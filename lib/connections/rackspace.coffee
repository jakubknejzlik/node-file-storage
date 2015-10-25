Uploader = require('s3-streaming-upload').Uploader
Downloader = require('s3-download-stream')
pkgcloud = require('pkgcloud')

Connection = require('../Connection')

class RackspaceConnection extends Connection
  connect:(callback)->
    @client = pkgcloud.storage.createClient({
      provider: 'rackspace',
      username: @settings.user,
      apiKey: @settings.password,
      region: @settings.region or 'IAD',
      useInternal: @settings.usingInternal or false
    })
    callback()

  close:(callback)->
    callback()

  saveStream: (stream, id, callback) ->
    writeStream = @client.upload({
      container: @_containerName(),
      remote: id
    })

    writeStream.on('error', callback)

    writeStream.on('success', (file)->
      callback(null,{id:id})
    )

    stream.pipe(writeStream)

  getStream: (id, callback) ->
    stream = @client.download({
      container: @_containerName(),
      remote: id
    })
    callback(null,stream)

  remove: (id, callback) ->
    @client.removeFile(@_containerName(),id,callback)

  _containerName: ()->
    return @settings.host.replace(/\//g,'')

module.exports = RackspaceConnection