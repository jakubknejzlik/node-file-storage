var assert = require('assert');
var fs = require('fs');
var homeDir = require('expand-home-dir');
var streamBuffers = require('stream-buffers');
var streamToBuffer = require('stream-to-buffer');
var async = require('async')

var FileManager = require('../index.js');


//var tmpDir = __dirname + '/tmp'


describe('filestorage',function(){
    var urls = ['file://localhost/tmp?ttl=1']
    var fms = []

    it('should connect using fs',function(done){
        async.forEach(urls,function(url,cb){
            var fm = new FileManager(url); // supply valid credentials
            fms.push(fm);
            cb()
        },done)
    })

    it('should store files',function(done){
        async.forEach(fms,function(fm,cb){
            fm.saveStream(fs.createReadStream(__dirname + '/test.txt'),function(err,info){
                if(err)return cb(err);
                fm.fileId = info.id;
                cb();
            })
        },done)
    })

    it('should delete files',function(done){
        async.forEach(fms,function(fm,cb){
            fm.remove(fm.fileId,cb)
        },done)
    })


    it('should store files',function(done){
        async.forEach(fms,function(fm,cb){
            fm.saveStream(fs.createReadStream(__dirname + '/test.txt'),cb)
        },done)
    })

})