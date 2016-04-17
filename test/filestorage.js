var assert = require('assert');
var fs = require('fs');
var homeDir = require('expand-home-dir');
var streamBuffers = require('stream-buffers');
var streamToBuffer = require('stream-to-buffer');
var async = require('async')

var FileStorage = require('../index.js');


//var tmpDir = __dirname + '/tmp'


describe('filestorage',function(){
    var urls = ['file://localhost/tmp?ttl=1']
    var fms = []

    before(function(done) {
        if(process.env.S3_URL)urls.push(process.env.S3_URL)
        async.forEach(urls, function (url, cb) {
            var fm = new FileStorage(url); // supply valid credentials
            fms.push(fm);
            cb()
        }, done)
    })

    it('should store files',function(done){
        this.timeout(300000)
        async.times(2000,function(i,cb){
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
        async.forEach(fms,function(fm,cb){
            async.forEach(fm.fileIds,function(fileId,cb) {
                fm.remove(fileId).then(cb).catch(cb)
            },cb)
        },done)
    })


    // it('should store files',function(done){
    //     async.forEach(fms,function(fm,cb){
    //         fm.saveStream(fs.createReadStream(__dirname + '/test.txt')).then(function(info){
    //             cb()
    //         }).catch(cb)
    //     },done);
    // })

})