var assert = require('assert');
var fs = require('fs');
var streamBuffers = require('stream-buffers');
var streamToBuffer = require('stream-to-buffer');

var async = require('async');
var homeDir = require('expand-home-dir');

//var Connection = require('../connections/file');

var connectionUrls = {}

connectionUrls['file'] = 'file://localhost/tmp';
//connectionUrls['s3'] = 's3://{key}:{privateKey}@{bucket}?region=eu-central-1';
//connectionUrls['ftp'] = 'ftp://file-manager-test.wz.cz:...@file-manager-test.wz.cz';
//connectionUrls['sftp'] = 'sftp://root@vps.knejzlik.cz/tmp?privateKey='+encodeURIComponent(fs.readFileSync(homeDir('~/.ssh/id_dsa')))+'&passphrase=...'
//connectionUrls['mongodb'] = 'mongodb://localhost/fs-test';
//connectionUrls['rackspace'] = 'rackspace://jakubknejzlik:...@...';


describe('connections',function(){
    var connections = {}; // supply valid credentials
    var attempts = new Array(50)

    before(function(){
        for(var i in connectionUrls){
            connections[i] = new (require('../connections/' + i))(connectionUrls[i]);
        }
    })

    it('should connect',function(done){
        async.forEach(Object.keys(connections),function(connectionType,cb){
            connections[connectionType].connect(cb);
        },done);
    })

    it('should store stream',function(done){
        async.forEach(attempts,function(x,_cb){
            async.forEach(Object.keys(connections),function(connectionType,cb){
                var connection = connections[connectionType];
                connection.saveStream(fs.createReadStream(__dirname + '/test.txt'),'test.txt',function(err,info){
                    if(err)return cb(err);
                    connection.fileId = info.id;
                    cb();
                });
            },_cb)
        },done)
    })

    it('should load stream',function(done){
        async.forEach(attempts,function(x,_cb){
            async.forEach(Object.keys(connections),function(connectionType,cb){
                var connection = connections[connectionType];
                connection.getStream(connection.fileId,function(err,stream){
                    if(err)return done(err);
                    streamToBuffer(stream,function(err,buffer){
                        if(err)return cb(err);
                        assert.equal(fs.readFileSync(__dirname + '/test.txt').toString('utf-8'),buffer.toString('utf-8'))
                        cb()
                    })
                })
            },_cb)
        },done)
    })

    it('should override stream',function(done){
        async.forEach(Object.keys(connections),function(connectionType,cb){
            var connection = connections[connectionType];
            connection.saveStream(fs.createReadStream(__dirname + '/test2.txt'),'test',function(err,info){
                if(err)return cb(err);
                connection.fileId = info.id;
                cb();
            });
        },done)
    })

    it('should load overridden stream',function(done){
        async.forEach(Object.keys(connections),function(connectionType,cb){
            var connection = connections[connectionType];
            connection.getStream(connection.fileId,function(err,stream){
                if(err)return done(err);
                streamToBuffer(stream,function(err,buffer){
                    if(err)return cb(err);
                    assert.equal(fs.readFileSync(__dirname + '/test2.txt').toString('utf-8'),buffer.toString('utf-8'))
                    cb()
                })
            })
        },done)
    })

    it('should remove file',function(done){
        async.forEach(Object.keys(connections),function(connectionType,cb){
            var connection = connections[connectionType];
            connection.remove(connection.fileId,cb)
        },done);
    })

    it('should return error on nonexisting file',function(done){
        async.forEach(Object.keys(connections),function(connectionType,cb){
            var connection = connections[connectionType];
            connection.getStream('blahfilenonexisting',function(err,stream){
                assert.ok(!!err)
                assert.ok(!stream)
                cb()
            })
        },done);
    })

    it('should disconnect',function(done){
        async.forEach(Object.keys(connections),function(connectionType,cb){
            var connection = connections[connectionType];
            connection.close(cb)
        },done);
    })
})