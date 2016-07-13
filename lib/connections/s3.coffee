aws = require('aws-sdk')
fs = require('fs')
mime = require('mime-types')

Connection = require('../Connection')

class S3Connection extends Connection
  connect:(callback)->
    @client = new aws.S3({
      accessKeyId: @_getKeyId()
      secretAccessKey: @_getSecretKey(),
      signatureVersion:@_getSignatureVersion(),
      region:@_getRegion(),
      logger: if process.env.FILE_STORAGE_S3_LOGGING then process.stdout else null
    })
    callback()

  close:(callback)->
    callback()

  saveStream: (stream, id, callback) ->
    upload = new aws.S3.ManagedUpload({
      service:@client,
      params:{
        Bucket: @_bucketName(),
        Key: @getPath(id),
        Body: stream,
        ContentType: mime.lookup(id) or 'application/octet-stream'
      }
    })
    upload.send((err,info)->
      info.id = id if info
      callback(err,info)
    )

  getStream: (id, callback) ->
    stream = @client.getObject({
      Bucket: @_bucketName(),
      Key: @getPath(id)
    }).createReadStream()
    stream.on('error',callback)
    stream.once('readable',()->
      callback(null,stream)
    )

  remove: (id, callback) ->
    @client.deleteObject({
      Key:@getPath(id),
      Bucket: @_bucketName()
    },callback)

  getPath: ()->
    path = super
    path = path.substring(1)
    return path

  _partSize:()->
    return @settings.partSize or 1*1024*1024

  _queueSize:()->
    return @settings.queueSize or 5

  _getRegion:()->
    return @settings.region

  _getSignatureVersion:()->
    return @settings.signatureVersion or 'v4'

  _bucketName:()->
    return @settings.host or @settings.bucket

  _getKeyId:()->
    return @settings.user or @settings.accessKeyId

  _getSecretKey:()->
    return @settings.password or @settings.secretAccessKey

module.exports = S3Connection