var assert = require('assert');
var fs = require('fs');
var streamToBuffer = require('stream-to-buffer');

var Promise = require('bluebird')
var homeDir = require('expand-home-dir');

//var Connection = require('../connections/file');

var connectionUrls = {}

connectionUrls['file'] = 'file://localhost/tmp';

if(process.env.S3_URL)connectionUrls['s3'] = process.env.S3_URL;
//connectionUrls['ftp'] = 'ftp://file-manager-test.wz.cz:...@file-manager-test.wz.cz';
//connectionUrls['sftp'] = 'sftp://{user}@{host}/{path}?privateKey='+encodeURIComponent(fs.readFileSync(homeDir('~/.ssh/id_dsa')))+'&passphrase=...'
//connectionUrls['mongodb'] = 'mongodb://localhost/fs-test';
//connectionUrls['rackspace'] = 'rackspace://jakubknejzlik:...@...';


describe('connections',function(){
    var connections = {}; // supply valid credentials
    var attempts = new Array(50)

    before(function(){
        for(var i in connectionUrls){
            connections[i] = new (require('../lib/connections/' + i))(connectionUrls[i]);
        }
    })

    before('should connect',function(){
        Promise.each(Object.keys(connections),function(connectionType){
            return connections[connectionType].connect()
        })
    })

    it('should store stream',function(){
        Promise.each(attempts,function(x,_cb){
            Promise.each(Object.keys(connections),function(connectionType,cb){
                var connection = connections[connectionType];
                connection.saveStream(fs.createReadStream(__dirname + '/test.txt'),'test.txt').then(function(info){
                    connection.fileId = info.id;
                });
            })
        })
    })

    it('should load stream',function(){
        Promise.each(attempts,function(x){
            Promise.each(Object.keys(connections),function(connectionType,cb){
                var connection = connections[connectionType];
                connection.getStream(connection.fileId).then(function(stream){
                    return new Promise(function(reject, resolve) {
                        streamToBuffer(stream, function (err, buffer) {
                            if (err)return reject(err);
                            assert.equal(fs.readFileSync(__dirname + '/test.txt').toString('utf-8'), buffer.toString('utf-8'))
                            resolve()
                        })
                    })
                })
            })
        })
    })

    describe('stream overriding',function(){
        before('should override stream',function(){
            Promise.each(Object.keys(connections),function(connectionType){
                var connection = connections[connectionType];
                connection.saveStream(fs.createReadStream(__dirname + '/test2.txt'),'test2.txt').then(function(info){
                    connection.fileId = info.id;
                });
            })
        })

        it('should load overridden stream',function(){
            Promise.each(Object.keys(connections),function(connectionType){
                var connection = connections[connectionType];
                connection.getStream(connection.fileId).then(function(stream){
                    return new Promise(function(resolve, reject){
                        streamToBuffer(stream,function(err,buffer){
                            if(err)return reject(err);
                            assert.equal(fs.readFileSync(__dirname + '/' + connection.fileId).toString('utf-8'),buffer.toString('utf-8'))
                            resolve()
                        })
                    })
                })
            })
        })

        it('should remove file',function(){
            Promise.each(Object.keys(connections),function(connectionType){
                var connection = connections[connectionType];
                return connection.remove(connection.fileId)
            });
        })
    })

    it('should return error on nonexisting file',function(){
        Promise.each(Object.keys(connections),function(connectionType){
            var connection = connections[connectionType];
            connection.getStream('blahfilenonexisting').then(function(stream){
                assert.ok(!stream)
            })
        });
    })

    it('should disconnect',function(){
        Promise.each(Object.keys(connections),function(connectionType){
            var connection = connections[connectionType];
            return connection.close()
        });
    })
})