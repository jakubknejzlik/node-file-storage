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

    it('should connect using fs',function(done){
        async.forEach(urls,function(url,cb){
            var fm = new FileStorage(url); // supply valid credentials
            fms.push(fm);
            cb()
        },done)
    })

    it('should store files',function(done){
        async.forEach(fms,function(storage,cb){
            storage.saveStream(fs.createReadStream(__dirname + '/test.txt')).then(function(info){
                storage.fileId = info.id;
                cb();
            }).catch(cb)
        },done)
    })

    it('should delete files',function(done){
        async.forEach(fms,function(fm,cb){
            fm.remove(fm.fileId).then(cb).catch(cb)
        },done)
    })


    it('should store files',function(done){
        async.forEach(fms,function(fm,cb){
            fm.saveStream(fs.createReadStream(__dirname + '/test.txt')).then(function(info){
                cb()
            }).catch(cb)
        },done);
    })

})