url = require('url')
queryString = require('query-string')
path = require('path')
streamifier = require('streamifier')
streamToBuffer = require('stream-to-buffer');
Promise = require('bluebird')

class Connection
  constructor:(@settings)->
    if typeof @settings is 'string'
      @settings = url.parse(@settings)
    if @settings.auth
      [@settings.user,@settings.password] = @settings.auth.split(':')
      @settings.username = @settings.user
    if @settings.query
      query = queryString.parse(@settings.query)
      for key,value of query
        @settings[key] = value

  connect:()->
    return Promise.reject('not implemented')

  close:()->
    return Promise.reject('not implemented')

  saveStream: (stream, id) ->
    return Promise.reject('not implemented')

  saveData: (data, id) ->
    stream = streamifier.createReadStream(data)
    return @saveStream(stream, id)

  getStream: (id) ->
    return Promise.reject('not implemented')

  getData: (id) ->
    return @getStream(id).then((stream)=>
      return new Promise((resolve, reject)->
        streamToBuffer(stream,(err,data)->
          return reject(err) if err
          resolve(data)
        )
      )
    )

  getPath:(id = '')->
    return path.join(@settings.pathname or '/',String(id))

module.exports = Connection