fs = require 'fs'
path = require 'path'
diff = require 'diff'
sleep = require('sleep').sleep

class Diff
  constructor : (@filepath) ->
    @range = 5
    @filename = path.basename @filepath
    await @update defer(err, chunks)
    if err
      console.error "Error monitoring #{@filepath}: file does not exist"
    else
      console.log "Monitoring #{@filepath}"

  update : (force = false, cb) ->
    if @cur?
      @prev = @cur
    else
      await fs.readFile @filepath, {encoding: 'utf8'}, defer err, data
      @cur =
        content: !err? && data || ''
        time: Date.now()
      return
    await fs.readFile @filepath, {encoding: 'utf8'}, defer err, data
    if force
      while data is ''
        console.log "[DIFF] Delayed read (NodeJS is so weird)"
        data = fs.readFileSync @filepath, 'utf8'
        sleep 1
    @cur =
      content: !err? && data || ''
      time: Date.now()
    res = diff.diffLines @prev.content, @cur.content
    return unless res.length > 1 or (res[0].added? or res[0].removed?)

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
    cb and cb null, chunks

module.exports = Diff
