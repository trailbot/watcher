fs = require 'fs'
path = require 'path'
diff = require 'diff'

class Diff
  constructor : (@filepath) ->
    @cur = ''
    @range = 5
    @filename = path.basename @filepath
    await @update defer()
    console.log "Monitoring #{@filepath}"

  update : (cb) ->
    @prev = @cur
    await fs.readFile @filepath, {encoding: 'utf8'}, defer err, data
    @cur = data
    res = diff.diffLines @prev, @cur
    offset = 1
    chunks = []
    res.forEach (cur, i, a) =>
      type = (cur.added && 'add') || (cur.removed && 'rem')
      if type
        chunks.push
          type: type
          start: offset
          lines: cur.value.split('\n').slice(0, cur.count)
      else
        if cur.count > @range
          size = Math.floor(@range / 2 )
          if i > 0
            chunks.push
              type: 'fill'
              start: offset
              lines: cur.value.split('\n').slice(0, size + 1)
            offset += size
          chunks.push
            type: 'ellipsis'
            size: cur.count - size
          offset += cur.count - size
          if i < a.length - 1
            chunks.push
              type: 'fill'
              start: offset
              lines: cur.value.split('\n').slice(-size-1, -1)
            offset += size
          offset -= cur.count
        else
          chunks.push
            type: 'fill'
            start: offset
            lines: cur.value.split('\n').slice(0, cur.count)
      offset += cur.count
    cb and cb chunks

  patch : (cb) ->
    return setTimeout @patch.bind(this, cb), 500 if not @cur

    await fs.readFile @filepath, {encoding: 'utf8'}, defer err, data
    cb diff.createPatch @filename, @cur, data

module.exports = Diff
