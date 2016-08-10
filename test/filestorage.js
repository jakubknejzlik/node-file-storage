var assert = require('assert');
var fs = require('fs');
var homeDir = require('expand-home-dir');
var streamToBuffer = require('stream-to-buffer');
var async = require('async')
var Promise = require('bluebird')

var FileStorage = require('../index.js');


//var tmpDir = __dirname + '/tmp'


describe.only('filestorage',function(){
    var urls = ['file://localhost/tmp?ttl=1']
    var fms = []

    before(function() {
        if(process.env.S3_URL)urls.push(process.env.S3_URL)
        Promise.each(urls, function (url) {
            fms.push(new FileStorage(url))
        })
    })

    it('should store files',function(done){
        this.timeout(300000)
        async.times(20,function(i,cb){
            async.forEach(fms,function(storage,cb){
                storage.saveData(fs.readFileSync(__dirname + '/test.txt'),'test/' + i + '.txt').then(function(info){
                    storage.fileIds = storage.fileIds || [];
                    storage.fileIds.push(info.id);
                    cb();
                }).catch(cb)
            },cb)
        },done)
    })

    it('should delete files',function(done){
        this.timeout(300000)
        async.forEach(fms,function(fm,cb){
            async.forEach(fm.fileIds,function(fileId,cb) {
                fm.remove(fileId).then(function() {
                    cb()
                }).catch(cb)
            },cb)
        },done)
    })

})