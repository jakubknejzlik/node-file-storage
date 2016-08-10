fs = require("fs")
path = require('path')
Lock = require('lock')
Promise = require('bluebird')

Connection = require('../Connection')

lock = Lock()

class FileConnection extends Connection
  connect:()->
    return Promise.try(()=>
      if not @settings.path
        throw new Error("settings.path must be specified")
    )

  close:()->

  ensureDirectory:(id)->
    return new Promise((resolve, reject)=>
      callback = (err)->
        return reject(err) if err
        return resolve()
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
    )

  saveStream:(stream,id)->
    @ensureDirectory(id).then(()=>
      @_saveStream(stream,id)
    )

  _saveStream: (stream, id) ->
    return new Promise((resolve, reject)=>
      writeStream = fs.createWriteStream(@getPath(id))

      stream.on("end", ->
        resolve({id: id})
      )

      stream.on("error", (err) ->
        reject(err)
      )

      stream.pipe(writeStream)
    )

  getStream: (id) ->
    return new Promise((resolve, reject)=>
      filename = @getPath(id)
      fs.exists(filename,(exists)=>
        if not exists
          return reject(new Error('record '+id+' doesn\'t exists'))
        resolve(fs.createReadStream(filename))
      )
    )

  remove: (id) ->
    return new Promise((resolve, reject)=>
      fs.unlink(@getPath(id),(err)->
        return reject(err) if err
        resolve()
      )
    )

module.exports = FileConnection