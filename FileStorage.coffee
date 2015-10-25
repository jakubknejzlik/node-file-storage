streamToBuffer = require('stream-to-buffer');
streamBuffers = require('stream-buffers');
url = require('url')
queryString = require('query-string')
md5 = require('md5')

GenericPool = require('generic-pool')

class FileManager
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

    @type = @settings.protocol?.replace(':','')
    @pool = GenericPool.Pool({
      name:@type
      create: (callback)=>
        Connection = require(__dirname + "/connections/" + @type + ".js")
        connection = new Connection(@settings)
        connection.connect((err)=>
          callback(err) if err
          callback(null,connection)
        )
      destroy:(connection)=>
        connection.close(()->)
      max: @settings.maxConnections or 1,
      idleTimeoutMillis:1000*(@settings.ttl or 60)
    })


  saveStream: (stream, id, callback) ->
    if typeof id is 'function'
      callback = id
      id = @getNewId()
    callback = callback or ()->
    @pool.acquire((err,connection)=>
      connection.saveStream(stream,id,(err,info)=>
        @pool.release(connection)
        callback(err,info)
      )
    )

  saveData:(data,id,callback)->
    streamBuffer = new streamBuffers.ReadableStreamBuffer()
    streamBuffer.put(data)
    @saveStream(streamBuffer,String(id),callback)
    streamBuffer.destroySoon()


  getStream: (id, callback) ->
    callback = callback or ()->
    @pool.acquire((err,connection)=>
      connection.getStream(id,(err, stream)=>
        @pool.release(connection)
        return callback(err) if err
        callback(null, stream)
      )
    )

  getData:(id,callback)->
    callback = callback or ()->
    @getStream(String(id),(err,stream)=>
      return callback(err) if err
      streamToBuffer(stream,callback)
    )

  getNewId:()->
    return md5((Math.random() * 100000) + Date.now())

  remove: (id, callback) ->
    @pool.acquire((err,connection)=>
      connection.remove(String(id),(err)=>
        @pool.release(connection)
        callback(err)
      )
    )

module.exports = FileManager