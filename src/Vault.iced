Horizon = require '@horizon/client/dist/horizon'

class Vault
  constructor : (host, secret, cb) ->
    @secret = secret

    authType = 'anonymous'
    @hz = Horizon({host, authType})
    @hz.connect()
    @users = @hz 'users'
    @settings = @hz 'settings'
    @diffs = @hz 'diffs'

    @hz.onReady () =>
      cb and cb this

  save : (col, object, cb) ->
    console.log "Saving into #{col}"
    this[col]?.store object
    cb and cb true

  get : (col, cb) ->
    this[col]?.fetch().subscribe (items) ->
      cb and cb items

  getOne : (col, cb) ->
    @get col, (items) ->
      cb items[0]

  remove : (col, ids, cb) ->
    console.log "Removing from #{col}"
    res = this[col].removeAll(ids)
    cb and cb res


module.exports = Vault
