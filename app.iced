'use strict'

fs = require 'fs'
path = require 'path'
chokidar = require 'chokidar'
extend = require('util')._extend

Config = require './src/Config'
Crypto = require './src/Crypto'
Diff = require './src/Diff'
Vault = require './src/Vault'
Sandbox = require  './src/Sandbox'

process.on 'uncaughtException', (err) ->
  console.error err.stack
  console.log 'Node NOT exiting...'
  return

app = class App
  constructor : ->
    @watcher = null

    await new Crypto Config.watcher_key, Config.client_key, defer @cryptoBox
    @watcherFP = @cryptoBox.watcherKey.get_pgp_fingerprint().toString('hex')
    @clientFP  = @cryptoBox.clientKey.get_pgp_fingerprint().toString('hex')
    console.log 'Watcher fingerprint:', @watcherFP
    console.log 'Client fingerprint', @clientFP

    await new Vault this, Config.vault, @watcherFP, @clientFP, defer @vault
    console.log 'Connected to vault'

    @vault.watch 'settings', {reader: @watcherFP}, (settings) =>
      if settings
        console.log 'Decrypting...'
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
      .on 'change', (path, stats) =>
        file = @files[path]
        await file.differ.update defer err, changes
        console.log "Change detected in #{path}"

        await @cryptoBox.encrypt JSON.stringify(changes), path, defer err, encrypted
        await vault.save 'diffs',
          creator: @watcherFP
          reader: @clientFP
          content: encrypted
          datetime: new Date()
          v: 1

        for policy in file.policies
          console.log "Must enforce policy #{policy.sandbox.name}"
          policy.sandbox.send changes

module.exports = new app()
