Config = require './Config'
Horizon = require '@horizon/client/dist/horizon'

class Vault
  constructor : (app, host, watcherFP, cb) ->
    @app = app
    authType = @getToken()
    secure = Config.secure
    @hz = Horizon({host, authType, secure})

    @hz.connect()
    @users = @hz 'users'
    @settings = @hz 'settings'
    @events = @hz 'events'
    @exchange = @hz 'exchange'

    @hz.onReady () =>
      token = JSON.parse(@hz.utensils.tokenStorage._storage._storage.get('horizon-jwt')).horizon
      @app.localStorage.setItem 'horizon_jwt', token
      @hz.currentUser().fetch().subscribe (me) =>
        me.data =
          key: watcherFP
        @users.replace me
        console.log 'Me:', me if @app.emit
        @app.emit 'vaultLoggedIn', me if @app.emit
        cb and cb this

    @hz.onDisconnected (e) =>
      unless @retried
        @retried = true
        @app.localStorage.removeItem 'horizon_jwt'
        @constructor app, host, watcherFP, cb

  getToken : () ->
    jwt = @app.localStorage.getItem 'horizon_jwt'
    if jwt
      { token: jwt, storeLocally: false }
    else
      'anonymous'

  save : (col, object, cb) ->
    console.log "Saving into #{col}" if @app.emit
    console.log 'SAVING', object if @app.emit
    this[col]?.store(object).subscribe(cb)

  replace : (col, object) ->
    console.log "Replacing into #{col}" if @app.emit
    this[col]?.replace object

  get : (col, query, cb) ->
    this[col]?.find(query).fetch().defaultIfEmpty().subscribe(cb)

  watch : (col, query, cb, err) ->
    this[col]?.find(query).watch().subscribe(cb, err)

  remove : (col, ids) ->
    console.log "Removing from #{col}" if @app.emit
    this[col].removeAll(ids)

  getCollection : () ->
    @exchange


module.exports = Vault
