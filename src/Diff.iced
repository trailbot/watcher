fs = require 'fs'
path = require 'path'
diff = require 'diff'

class Diff
  constructor : (@filepath) ->
    @cur = ''
    @filename = path.basename @filepath
    await @update defer()
    console.log "Monitoring #{@filepath}"

  update : (cb) ->
    @prev = @cur
    await fs.readFile @filepath, {encoding: 'utf8'}, defer err, data
    @cur = data
    cb and cb diff.diffLines @prev, @cur

  patch : (cb) ->
    return setTimeout @patch.bind(this, cb), 500 if not @cur

    await fs.readFile @filepath, {encoding: 'utf8'}, defer err, data
    cb diff.createPatch @filename, @cur, data

module.exports = Diff

