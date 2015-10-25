# file-storage

[![Build Status](https://travis-ci.org/jakubknejzlik/node-file-storage.svg?branch=master)](https://travis-ci.org/jakubknejzlik/node-file-storage)
[![NPM Version][npm-image]][npm-url]
[![NPM Downloads][downloads-image]][downloads-url]

[![dependencies][dependencies-image]][dependencies-url]
[![devdependencies][devdependencies-image]][devdependencies-url]

[npm-image]: https://img.shields.io/npm/v/file-storage.svg
[npm-url]: https://npmjs.org/package/file-storage
[downloads-image]: https://img.shields.io/npm/dm/file-storage.svg
[downloads-url]: https://npmjs.org/package/file-storage

[dependencies-image]:https://david-dm.org/jakubknejzlik/node-file-storage.png
[dependencies-url]:https://david-dm.org/jakubknejzlik/node-file-storage
[devdependencies-image]:https://david-dm.org/jakubknejzlik/node-file-storage/dev-status.png
[devdependencies-url]:https://david-dm.org/jakubknejzlik/node-file-storage#info=devDependencies


File storage for storing/retrieving files from various sources.

# Instalation

`npm install file-storage`


# Example

```
var fs = require('fs');
var FileManager = require('file-storage');

var fileReadStream = fs.createReadStream(...);
var fileWriteStream = fs.createWriteStream(...);

var storage = new FileStorage(...); // supply valid credentials

storage.saveStream(fileStream).then(function(info){
    console.log('file info:', info.id);
});

storage.getStream('file_id').then(function(stream){
    stream.pipe(fileWriteStream);
});
```

# API

## FileStorage

- `new FileStorage(url)`
    - *url* – connection URL for file source.

### Instance methods
All methods returns promise (callback as last argument is supported). Attribute `id` identify file entries. For save operations `id` is not required (UUID is generated).
- `getStream(id)`
- `getData(id)`
- `saveStream(stream[,id])`
- `saveData(data[,id])`
- `remove(id)`

When save is successfuly completed, the `info` is returned as first argument. Every storage type returns it's own informations (at least file identifier at `info.id`)


# URL String – Supported connections

- File System
    - `file://localhost/{path}`
- FTP
    - `ftp://{user}:{password}@{host}/{path}`
- SFTP
    - `sftp://{user}@{host}/{path}?privateKey='+encodeURIComponent(fs.readFileSync(homeDir('~/.ssh/id_dsa')))+'&passphrase=...`
- Amazon S3
    - `s3://{key}:{privateKey}@{bucket}?region={region}`
- MongoDB
    - `mongodb://{host}/{database}`
- Rackspace
    - `rackspace://{username}:{password}@{host}`

Connection string enabled multiple connections. By specifying`?maxConnections=...&ttl=...` you can define multiconnections behaviour:
- `maxConnections` – maximum number of connections in pool (default: 1)
- `ttl` – time to live for one connection without use before closing (default: 60s)

