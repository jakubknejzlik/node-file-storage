ftp = require('ftp')

Connection = require('../Connection')

class FTPConnection extends Connection

  connect:(callback)->
    @client = new ftp()
    @client.connect(@settings)
    @client.once('ready',callback)

  close:(callback)->
    @client.end()
    callback()

  saveStream: (stream, id, callback) ->
    @client.put(stream,@getPath(id),(err)->
      return callback(err) if err
      callback(null,{id:id})
    )

  getStream: (id, callback) ->
    @client.get(@getPath(id),callback)


  remove: (id, callback) ->
    @client.delete(@getPath(id),callback)

module.exports = FTPConnection