fs = require 'fs'
watch = require 'watch'

Crypto = require './src/Crypto'
Diff = require './src/Diff'
Mothership = require './src/Mothership'

logfile = 'system.log'

cryptoBox = new Crypto './keys/watcher.pgp', './keys/mothership.pgp'
mothership = new Mothership 'localhost:5000', cryptoBox

diff = new Diff logfile
fs.watchFile logfile, (curr, prev) ->
  if curr.mtime isnt prev.mtime
    console.log 'Modified'
    await diff.patch defer patch
    mothership.send patch
