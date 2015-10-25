ssh = require('ssh2')
path = require('path')

Connection = require('../Connection')

class FTPConnection extends Connection
  connect:(callback)->
    @connection = new ssh()
    @connection.connect(@settings)
    @connection.once('ready',()=>
      @connection.sftp((err,client)=>
        return callback(err) if err
        @client = client
        callback()
      )
    )

  close:(callback)->
    @client.end()
    callback()

  saveStream: (stream, id, callback) ->
    writeStream = @client.createWriteStream(@getPath(id))

    stream.pipe(writeStream)

    stream.on('error',callback)
    stream.on('end',()->
      callback(null,{id:id})
    )

  getStream: (id, callback) ->
    stream = @client.createReadStream(@getPath(id))
    callback(null,stream)


  remove: (id, callback) ->
    @client.unlink(@getPath(id),callback)

module.exports = FTPConnection