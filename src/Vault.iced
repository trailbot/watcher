Config = require './Config'
Horizon = require '@horizon/client/dist/horizon'

class Vault
  constructor : (app, host, watcherFP, clientFP, cb) ->
    @app = app
    authType = @getToken()
    secure = Config.secure
    @hz = Horizon({host, authType, secure})

    @hz.connect()
    @users = @hz 'users'
    @settings = @hz 'settings'
    @events = @hz 'events'

    @hz.onReady () =>
      token = JSON.parse(@hz.utensils.tokenStorage._storage._storage.get('horizon-jwt')).horizon
      @app.localStorage.setItem 'horizon_jwt', token
      @hz.currentUser().fetch().subscribe (me) =>
        unless me.data
          me.data =
            key: watcherFP
          @users.replace me
        console.log 'Me:', me
        @app.emit 'vaultLoggedIn', me
        cb and cb this

    @hz.onDisconnected (e) =>
      unless @retried
        @retried = true
        @app.localStorage.removeItem 'horizon_jwt'
        @constructor app, host, watcherFP, clientFP, cb

  getToken : () ->
    jwt = @app.localStorage.getItem 'horizon_jwt'
    if jwt
      { token: jwt, storeLocally: false }
    else
      'anonymous'

  save : (col, object, cb) ->
    console.log "Saving into #{col}"
    console.log 'SAVING', object
    this[col]?.store object
    cb and cb true

  replace : (col, object, cb) ->
    console.log "Replacing into #{col}"
    this[col]?.replace object
    cb and cb true

  get : (col, query, cb) ->
    this[col]?.find(query).fetch().subscribe (items) ->
      cb and cb items

  watch : (col, query, cb) ->
    this[col]?.find(query).watch().subscribe (items) ->
      cb and cb items

  remove : (col, ids, cb) ->
    console.log "Removing from #{col}"
    res = this[col].removeAll(ids)
    cb and cb res

module.exports = Vault
