// Generated by CoffeeScript 1.6.3
(function() {
  var StreamWithLength, running, stream, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  util = require("util");

  stream = require("stream");

  running = 0;

  StreamWithLength = (function(_super) {
    var _read;

    __extends(StreamWithLength, _super);

    function StreamWithLength(_stream, seekPosition, endPosition) {
      stream.Readable.call(this, _stream, seekPosition, endPosition);
      this.stream = _stream;
      this.endPosition = endPosition;
      this.seekPosition = seekPosition || 0;
      this.chunkLength = (this.endPosition ? this.endPosition - this.seekPosition + 1 : 0);
      this.currentPosition = this.seekPosition;
      return;
    }

    _read = function(size) {
      var self;
      self = this;
      if (self.reading && self.stream && self.stream.paused) {
        self.stream.resume();
      }
      if (self.reading) {
        return;
      }
      running++;
      self.reading = true;
      if (this.seekPosition >= this.endPosition) {
        running--;
        self.push(null);
        self.emit("end");
        self.emit("close");
        return;
      }
      self.stream.on("data", function(data) {
        console.log("uploading data", data.length);
        self.currentPosition += data.length;
        if (!self.push(data)) {
          self.stream.paused = true;
        }
      });
      self.stream.on("end", function() {
        console.log("end");
        self.emit("end");
      });
      self.stream.on("error", function(error) {
        console.log("error", error);
        self._error(error);
      });
      self.stream.on("close", function() {
        running--;
        console.log("close", running);
        self.reading = false;
        self.emit("close");
      });
    };

    return StreamWithLength;

  })(stream.Readable);

  module.exports = StreamWithLength;

}).call(this);
