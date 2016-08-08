class Event

  constructor : (@type, {@creator, @reader, @path, @payload}) ->
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
      creator:  @creator
      reader:   @reader
      content:  @encrypted
      datetime: new Date()
      v:        1
    , cb

module.exports = Event
