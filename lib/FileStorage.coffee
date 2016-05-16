streamToBuffer = require('stream-to-buffer');
streamBuffers = require('stream-buffers');
url = require('url')
queryString = require('query-string')
md5 = require('md5')
Q = require('q');
GenericPool = require('generic-pool')
uuid = require('uuid')
convert = require('unit-converter')
PassThrough = require('stream').PassThrough


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
      idleTimeoutMillis:convert(@settings.ttl or '60s').to('s')
    })


  saveStream: (stream, id, callback) ->
    deferred = Q.defer()
    if typeof id is 'function'
      callback = id
      id = @getNewId()
    id = String(id)
    @pool.acquire((err,connection)=>
      return deferred.reject(err) if err

      passThrough = new PassThrough()
      stream.pipe(passThrough)

      connection.saveStream(passThrough,id,(err,info)=>
        @pool.release(connection)
        return deferred.reject(err) if err
        info.id = id
        deferred.resolve(info)
      )
    )
    return deferred.promise.nodeify(callback)

  saveData:(data,id,callback)->
    deferred = Q.defer()
    if typeof id is 'function'
      callback = id
      id = @getNewId()
    id = String(id)
    streamBuffer = new streamBuffers.ReadableStreamBuffer()
    streamBuffer.put(data)
    streamBuffer.stop()
    @saveStream(streamBuffer,id,(err,info)->
      return deferred.reject(err) if err
      info.id = id
      deferred.resolve(info)
    )
    return deferred.promise.nodeify(callback)


  getStream: (id, callback) ->
    deferred = Q.defer()
    @pool.acquire((err,connection)=>
      connection.getStream(id,(err, stream)=>
        return deferred.reject(err) if err
        deferred.resolve(stream)
        released = no
        releaseCallback = ()=>
          console.log('release')
          @pool.release(connection) if not released
          released = yes

        stream.on('error',releaseCallback)
        stream.on('finish',releaseCallback)
        stream.on('end',releaseCallback)
        stream.on('close',releaseCallback)
      )
    )
    return deferred.promise.nodeify(callback)

  getData:(id,callback)->
    deferred = Q.defer()
    @getStream(String(id),(err,stream)=>
      return deferred.reject(err) if err
      streamToBuffer(stream,(err,data)->
        return deferred.reject(err) if err
        deferred.resolve(data)
      )
    )
    return deferred.promise.nodeify(callback)

  getNewId:()->
    return uuid.v4()

  remove: (id, callback) ->
    deferred = Q.defer()
    @pool.acquire((err,connection)=>
      connection.remove(String(id),(err)=>
        @pool.release(connection)
        return deferred.reject(err) if err
        deferred.resolve()
      )
    )
    return deferred.promise.nodeify(callback)

module.exports = FileManager