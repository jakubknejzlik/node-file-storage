fs = require("fs")

Connection = require('../Connection')

class FileConnection extends Connection
  connect:(callback)->
    unless @settings.path
      callback(new Error("settings.path must be specified"))
    else
      callback()

  close:(callback)->
    callback()

  saveStream: (stream, id, callback) ->
    writeStream = undefined
    try
      writeStream = fs.createWriteStream(@getPath(id))
    catch err
      callback(err)

    stream.on("end", ->
      callback(null,{id: id})
    )

    stream.on("error", (err) ->
      callback(err)
    )

    stream.pipe(writeStream)
    return

  getStream: (id, callback) ->
    path = @getPath(id)
    fs.exists(path,(exists)=>
      if not exists
        return callback(new Error('record '+id+' doesn\'t exists'))
      callback(null,fs.createReadStream(path))
    )


  remove: (id, callback) ->
    fs.unlink @getPath(id), callback
    return

module.exports = FileConnection