'use strict'

fs = require 'fs'
path = require 'path'
chokidar = require 'chokidar'
extend = require('util')._extend

EventEmitter = require 'events'
Config = require './Config'
Crypto = require './Crypto'
Diff = require './Diff'
Vault = require './Vault'
Sandbox = require  './Sandbox'
Event = require './Event'
Mods = require './Mods'

process.on 'uncaughtException', (err) ->
  console.error err.stack
  if err.message.indexOf 'transport close' > -1
    console.log '[WATCHER] Node exiting. If process is supervised, it will be respawned shortly.'
    process.exit 1
  else
    console.log '[WATCHER] Node NOT exiting...'
  return

app = class App extends EventEmitter
  constructor : ->
    @localStorage = new (require 'node-localstorage').LocalStorage(Config.local_storage)
    @watcher = null
    @defaults =
      files: {}
      policies: []

    # Initialize mods
    mods = @localStorage.getItem 'mods'
    if mods and mods.length
      mods = JSON.parse mods
      if mods
        for mod in mods
          if Mods[mod]?
            new Mods[mod](this)

    await new Crypto Config.watcher_priv_key, Config.client_pub_key, defer @cryptoBox
    @watcherFP = @cryptoBox.watcherKey.get_pgp_fingerprint().toString('hex')
    @clientFP  = @cryptoBox.clientKey.get_pgp_fingerprint().toString('hex')
    console.log '[WATCHER] Watcher fingerprint:', @watcherFP
    console.log '[WATCHER] Client fingerprint', @clientFP

    await new Vault this, Config.vault, @watcherFP, defer @vault
    @emit 'vaultConnected'
    console.log '[WATCHER] Connected to vault'

    @vault.watch 'settings', {reader: @watcherFP, creator: @clientFP}, (settings) =>
      console.log settings
      if settings
        @emit 'newSettings'
        if settings.content
          await @cryptoBox.decrypt settings, defer settings
        @processSettings settings

  processSettings : (settings) =>
    console.log '[WATCHER] New settings:', settings

    @files = {}
    Object.keys(settings.files).map (key) =>
      p = path.normalize key
      @files[p] = extend settings.files[key], {}
      @files[p].differ = new Diff p
      @files[p].policies = @files[p].policies.map (policy) ->
        policy.params.path = p
        console.log "[WATCHER] Creating Sandbox '#{policy.name}' (#{policy.uri}) for #{p}"
        policy.sandbox = new Sandbox policy, p
        policy

    if @watcher
      @watcher.close()

    @watcher = chokidar.watch Object.keys @files,
      awaitWriteFinish: true,
      atomic: true

    @watcher
      .on 'ready', () =>
        console.log '[WATCHER] Ready for changes!'
      .on 'change', (path, stats) => @eventProcessor 'change', path, stats
      .on 'unlink', (path, stats) => @eventProcessor 'unlink', path, stats
      .on 'add',    (path, stats) => @eventProcessor 'add', path, stats

  eventProcessor : (type, path, stats) =>
    file = @files[path]
    console.log "[WATCHER] #{type} detected in #{path}"

    force = type is 'change'
    await file.differ.update force, defer err, diff

    event = new Event type,
      path: path
      creator: @watcherFP
      reader:  @clientFP
      payload: type is 'change' and diff or undefined
    await event.encrypt @cryptoBox, defer()
    event.save @vault

    {prev, cur} = file.differ
    for policy in file.policies
      console.log "[WATCHER] Enforcing policy #{policy.sandbox.name}"
      policy.sandbox.send {diff, prev, cur}


module.exports = new app()
