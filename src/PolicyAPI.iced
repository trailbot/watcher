Config = require './Config'
Crypto = require './Crypto'
Vault = require './Vault'
Event = require './Event'

class PolicyAPI

  constructor: (@path)->
    @localStorage = new (require 'node-localstorage').LocalStorage(Config.local_storage)
    await new Crypto Config.watcher_priv_key, Config.client_pub_key, defer @cryptoBox
    @watcherFP = @cryptoBox.watcherKey.get_pgp_fingerprint().toString('hex')
    @clientFP  = @cryptoBox.clientKey.get_pgp_fingerprint().toString('hex')
    await new Vault this, Config.vault, @watcherFP, defer @vault

  raise: (type, payload, cb) =>
    #TODO may be instead of checkink here we should have a list of types not allowed
    if type.toLowerCase() != 'change' || 'link' != type.toLowerCase() || type.toLowerCase() != 'unlink'
      event = new Event type,
        path: @path
        creator: @watcherFP
        reader:  @clientFP
        payload: payload
      await event.encrypt @cryptoBox, defer()
      event.save @vault, cb

module.exports = PolicyAPI
