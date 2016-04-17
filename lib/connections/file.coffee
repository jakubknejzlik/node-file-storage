fs = require("fs")
path = require('path')
Lock = require('lock')

Connection = require('../Connection')

lock = Lock()

class FileConnection extends Connection
  connect:(callback)->
    unless @settings.path
      callback(new Error("settings.path must be specified"))
    else
      callback()

  close:(callback)->
    callback()

  ensureDirectory:(id,callback)->
    filename = @getPath(id)
    rootDir = @getPath()
    dir = path.dirname(filename)
    if dir is rootDir
      return callback()
    lock(dir,(release)=>
      callback = release(callback)
      fs.exists(dir,(exists)->
        if exists
          return callback()
        fs.mkdir(dir,callback)
      )
    )

  saveStream:(stream,id,callback)->
    @ensureDirectory(id,(err)=>
      return callback(err) if err
      @_saveStream(stream,id,callback)
    )

  _saveStream: (stream, id, callback) ->
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
    filename = @getPath(id)
    fs.exists(filename,(exists)=>
      if not exists
        return callback(new Error('record '+id+' doesn\'t exists'))
      callback(null,fs.createReadStream(filename))
    )


  remove: (id, callback) ->
    fs.unlink @getPath(id), callback
    return

module.exports = FileConnection