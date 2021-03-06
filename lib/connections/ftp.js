// Generated by CoffeeScript 1.10.0
(function() {
  var Connection, FTPConnection, ftp,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  ftp = require('ftp');

  Connection = require('../Connection');

  FTPConnection = (function(superClass) {
    extend(FTPConnection, superClass);

    function FTPConnection() {
      return FTPConnection.__super__.constructor.apply(this, arguments);
    }

    FTPConnection.prototype.connect = function(callback) {
      this.client = new ftp();
      this.client.connect(this.settings);
      return this.client.once('ready', callback);
    };

    FTPConnection.prototype.close = function(callback) {
      this.client.end();
      return callback();
    };

    FTPConnection.prototype.saveStream = function(stream, id, callback) {
      return this.client.put(stream, this.getPath(id), function(err) {
        if (err) {
          return callback(err);
        }
        return callback(null, {
          id: id
        });
      });
    };

    FTPConnection.prototype.getStream = function(id, callback) {
      return this.client.get(this.getPath(id), callback);
    };

    FTPConnection.prototype.remove = function(id, callback) {
      return this.client["delete"](this.getPath(id), callback);
    };

    return FTPConnection;

  })(Connection);

  module.exports = FTPConnection;

}).call(this);
