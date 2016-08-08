'use strict'

fs = require 'fs'
path = require 'path'
chokidar = require 'chokidar'
extend = require('util')._extend

Config = require './Config'
Crypto = require './Crypto'
Diff = require './Diff'
Vault = require './Vault'
Sandbox = require  './Sandbox'
Event = require './Event'

process.on 'uncaughtException', (err) ->
  console.error err.stack
  console.log '[WATCHER] Node NOT exiting...'
  return

app = class App
  constructor : ->
    @watcher = null

    await new Crypto Config.watcher_priv_key, Config.client_pub_key, defer @cryptoBox
    @watcherFP = @cryptoBox.watcherKey.get_pgp_fingerprint().toString('hex')
    @clientFP  = @cryptoBox.clientKey.get_pgp_fingerprint().toString('hex')
    console.log '[WATCHER] Watcher fingerprint:', @watcherFP
    console.log '[WATCHER] Client fingerprint', @clientFP

    await new Vault this, Config.vault, @watcherFP, @clientFP, defer @vault
    console.log '[WATCHER] Connected to vault'

    @vault.watch 'settings', {reader: @watcherFP, creator: @clientFP}, (settings) =>
      if settings
        console.log settings
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

    @watcher = chokidar.watch Object.keys @files
    @watcher
      .on 'ready', () =>
        console.log '[WATCHER] Ready for changes!'
      .on 'change', @processChange
      .on 'unlink', @processChange
      .on 'add', @processChange

  processChange : (path, stats) =>
    file = @files[path]
    if stats
      console.log "[WATCHER] Change detected in #{path}"
    else
      console.log "[WATCHER] Somehow lost sight of #{path}"

    await file.differ.update defer err, changes
    event = new Event 'change',
      path: path
      creator: @watcherFP
      reader:  @clientFP
      payload: changes
    await event.encrypt @cryptoBox, defer()
    event.save @vault

    {prev, cur} = file.differ

    for policy in file.policies
      console.log "[WATCHER] Enforcing policy #{policy.sandbox.name}"
      policy.sandbox.send changes, {prev, cur}

module.exports = new app()
