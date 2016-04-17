url = require('url')
queryString = require('query-string')
path = require('path')

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

  connect:(callback)->
    callback(new Error('not implemented'))

  close:(callback)->
    callback(new Error('not implemented'))


  saveStream: (stream, id, callback) ->
    callback(new Error('not implemented'))

  getStream: (id, callback) ->
    callback(new Error('not implemented'))

  getPath:(id = '')->
    return path.join(@settings.pathname or '',String(id))

module.exports = Connection