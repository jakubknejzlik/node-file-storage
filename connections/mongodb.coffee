mongo = require("mongodb")
Grid = require("gridfs-stream")

Connection = require('../Connection')

class MongoDBConnection extends Connection
  connect:(callback)->
    mongodb = new mongo.Db(@settings.pathname.replace('/',''), new mongo.Server(@settings.host or "127.0.0.1", @settings.port or 27017,{w:1}))
    mongodb.open((err)=>
      return callback(err) if err
      @connection = Grid(mongodb, mongo)
      callback()
    )

  close:(callback)->
    callback()

  saveStream: (stream, id, callback) ->
    writeStream = @connection.createWriteStream({
      _id: id
      mode: 'w'
    })
    bytesWrite = 0
    stream.on("data", (chunk) ->
      bytesWrite += chunk.length
      writeStream.write chunk
    )

    stream.on("end", ->
      return callback(new Error("no bytes sent"))  if bytesWrite is 0
      writeStream.end()
    )

    writeStream.on("close", (file) ->
      file.id = file._id.toString()
      callback(null, file)
    )

    writeStream.on "error", (err) ->
      callback(err)

    return

  getStream: (id, callback) ->
    id = ((if id.toHexString then id else @connection.tryParseObjectId(id)))
    gs = new mongo.GridStore(@connection.db, id, "r")
    gs.open (err, gs) ->
      return callback(err)  if err
      callback null, gs.stream(true), gs.length
      return

    return

  remove: (id, callback) ->
    id = ((if id.toHexString then id else @connection.tryParseObjectId(id)))
    @connection.remove
      _id: id
    , callback
    return

module.exports = MongoDBConnection