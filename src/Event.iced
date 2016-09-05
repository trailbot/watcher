class Event

  constructor : (@type, {@creator, @reader, @path, @payload}) ->
    @ref = Date.now()
    this

  encrypt : (crypto, cb) =>
    await crypto.encrypt @toString(), @path, defer err, @encrypted
    cb err, @encrypted if cb?

  toString : =>
    JSON.stringify
      type:    @type
      payload: @payload

  save : (vault, cb) =>
    vault.save 'events',
      ref:      @ref
      creator:  @creator
      reader:   @reader
      content:  @encrypted
      datetime: new Date()
      v:        1
    , cb

module.exports = Event
