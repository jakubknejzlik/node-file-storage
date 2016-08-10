url = require('url')
queryString = require('query-string')
md5 = require('md5')
Promise = require('bluebird');
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
        connection.connect().then(()->
          callback(null, connection)
        ).catch((err)->
          callback(err)
        )
      destroy:(connection)=>
        connection.close()
      max: @settings.maxConnections or 10,
      idleTimeoutMillis:convert(@settings.ttl or '60s').to('s')
    })


  getConnection: ()->
    return new Promise((resolve, reject)=>
      @pool.acquire((err,connection)=>
        return reject(err) if err
        resolve(connection)
      )
    )

  releaseConnection: (connection)->
    @pool.release(connection)
    return Promise.resolve()

    
  saveStream: (stream, id = @getNewId()) ->
    return @getConnection().then((connection)=>
      id = String(id)

      passThrough = new PassThrough()
      stream.pipe(passThrough)

      return connection.saveStream(passThrough,id).then((info)=>
        info.id = id
        return info
      ).finally(()=>
        @releaseConnection(connection)
      )
    )

  saveData:(data, id = @getNewId())->
    return @getConnection().then((connection)=>
      id = String(id)
      return connection.saveData(data,id).then((info)=>
        info.id = id
        return info
      ).finally(()=>
        @releaseConnection(connection)
      )
    )


  getStream: (id) ->
    return @getConnection().then((connection)=>
      return connection.getStream(id).then((stream)=>

        released = no
        releaseCallback = ()=>
          @pool.release(connection) if not released
          released = yes

        stream.on('error',releaseCallback)
        stream.on('finish',releaseCallback)
        stream.on('end',releaseCallback)
        stream.on('close',releaseCallback)
        setTimeout(releaseCallback,60000)

        return stream
      )
    )

  getData:(id)->
    return @getConnection().then((connection)=>
      return connection.getData(id).finally(()=>
        @releaseConnection(connection)
      )
    )

  getNewId:()->
    return uuid.v4()

  remove: (id) ->
    return @getConnection().then((connection)=>
      return connection.remove(id).finally(()=>
        @releaseConnection(connection)
      )
    )

module.exports = FileManager