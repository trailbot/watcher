Config = require './Config'
Horizon = require '@horizon/client/dist/horizon'
localStorage = new (require 'node-localstorage').LocalStorage(Config.local_storage)

class Vault
  constructor : (host, sec, pub, cb) ->
    authType = @getToken()
    @hz = Horizon({host, authType})
#    console.log "I am user", authType
    @hz.connect()
    @users = @hz 'users'
    @settings = @hz 'settings'
    @diffs = @hz 'diffs'

    @hz.onReady () =>
      token = JSON.parse(@hz.utensils.tokenStorage._storage._storage.get('horizon-jwt')).horizon
      localStorage.setItem 'horizon-jwt', token
      await @hz.currentUser().fetch().subscribe defer me
      unless me.data
        me.data = {sec, pub}
        @users.replace me
      console.log 'Me:', me
      cb and cb this

#    @hz.onDisconnected (e) =>
#      unless @retried
#        @retried = true
#        localStorage.removeItem 'horizon-jwt'
#        @constructor host, sec, pub, cb

  getToken : () ->
    jwt = localStorage.getItem 'horizon-jwt'
    if jwt
      { token: jwt, storeLocally: false }
    else
      'anonymous'

  save : (col, object, cb) ->
    console.log "Saving into #{col}"
    this[col]?.store object
    cb and cb true

  replace : (col, object, cb) ->
    console.log "Replacing into #{col}"
    this[col]?.replace object
    cb and cb true

  get : (col, cb) ->
    this[col]?.fetch().subscribe (items) ->
      cb and cb items

  getOne : (col, query, cb) ->
    this[col]?.find(query).fetch().subscribe (item) ->
      cb and cb item

  remove : (col, ids, cb) ->
    console.log "Removing from #{col}"
    res = this[col].removeAll(ids)
    cb and cb res


module.exports = Vault
