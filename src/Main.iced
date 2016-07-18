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

process.on 'uncaughtException', (err) ->
  console.error err.stack
  console.log 'Node NOT exiting...'
  return

app = class App
  constructor : ->
    @watcher = null

    await new Crypto Config.watcher_priv_key, Config.client_pub_key, defer @cryptoBox
    @watcherFP = @cryptoBox.watcherKey.get_pgp_fingerprint().toString('hex')
    @clientFP  = @cryptoBox.clientKey.get_pgp_fingerprint().toString('hex')
    console.log 'Watcher fingerprint:', @watcherFP
    console.log 'Client fingerprint', @clientFP

    await new Vault this, Config.vault, @watcherFP, @clientFP, defer @vault
    console.log 'Connected to vault'

    @vault.watch 'settings', {reader: @watcherFP, creator: @clientFP}, (settings) =>
      if settings
        console.log settings
        if settings.content
          await @cryptoBox.decrypt settings, defer settings
        @processSettings settings

  processSettings : (settings) =>
    console.log 'New settings:', settings

    @files = {}
    Object.keys(settings.files).map (key) =>
      p = path.normalize key
      @files[p] = extend settings.files[key], {}
      @files[p].differ = new Diff p
      @files[p].policies = @files[p].policies.map (policy) ->
        policy.params.path = p
        console.log 'Creating Sandbox for', policy
        policy.sandbox = new Sandbox policy
        policy

    if @watcher
      @watcher.close()

    @watcher = chokidar.watch Object.keys @files
    @watcher
      .on 'ready', () =>
        console.log 'Ready for changes!'
      .on 'change', @processChange
      .on 'unlink', @processChange
      .on 'add', @processChange

  processChange : (path, stats) =>
    file = @files[path]
    if stats
      console.log "Change detected in #{path}", stats
    else
      console.log "Somehow lost sight of #{path}"

    await file.differ.update defer err, changes
    await @cryptoBox.encrypt JSON.stringify(changes), path, defer err, encrypted
    await @vault.save 'diffs',
      creator: @watcherFP
      reader: @clientFP
      content: encrypted
      datetime: new Date()
      v: 1

    for policy in file.policies
      console.log "Must enforce policy #{policy.sandbox.name}"
      policy.sandbox.send changes

module.exports = new app()
