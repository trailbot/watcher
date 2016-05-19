fs = require 'fs'
watch = require 'watch'

Crypto = require './src/Crypto'
Diff = require './src/Diff'
Mothership = require './src/Mothership'
Git = require './src/Git'

logfile = 'repo/system.log'

#cryptoBox = new Crypto './keys/watcher.pgp', './keys/mothership.pgp'
#mothership = new Mothership 'localhost:5000', cryptoBox
#diff = new Diff logfile

git = new Git
fs.watchFile logfile, (curr, prev) ->
  if curr.mtime isnt prev.mtime
    console.log 'Modified'
    # mothership.send patch
    git.commit()
