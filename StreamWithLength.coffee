util = require("util")
stream = require("stream")

running = 0

class StreamWithLength extends stream.Readable
  constructor:(_stream, seekPosition, endPosition) ->
    stream.Readable.call this, _stream, seekPosition, endPosition
    @stream = _stream
    @endPosition = endPosition
    @seekPosition = seekPosition or 0
    @chunkLength = (if @endPosition then (@endPosition - @seekPosition + 1) else 0)
    @currentPosition = @seekPosition
    return

  _read = (size) ->
    self = this
    self.stream.resume()  if self.reading and self.stream and self.stream.paused
    return  if self.reading
    running++
    self.reading = true
    if @seekPosition >= @endPosition
      running--
      self.push null
      self.emit "end"
      self.emit "close"
      return
    self.stream.on "data", (data) ->
      console.log "uploading data", data.length

      #			if(this.endPosition >= self.currentPosition+data.length){
      #				console.log('fixing data length ',data.length,'=>',this.endPosition-self.currentPosition);
      #				data = data.slice(0,this.endPosition-self.currentPosition);
      #			}
      #			console.log('data length',data.length)
      self.currentPosition += data.length
      self.stream.paused = true  unless self.push(data)
      return

    self.stream.on "end", ->
      console.log "end"
      self.emit "end"
      return

    self.stream.on "error", (error) ->
      console.log "error", error
      self._error error
      return

    self.stream.on "close", ->
      running--
      console.log "close", running
      self.reading = false
      self.emit "close"
      return

    return

module.exports = StreamWithLength