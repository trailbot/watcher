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

app = {}

await new Crypto Config.watcher_key, Config.client_key, defer cryptoBox
watcherFP = cryptoBox.watcherKey.get_pgp_fingerprint().toString('hex')
clientFP  = cryptoBox.clientKey.get_pgp_fingerprint().toString('hex')
console.log 'Watcher fingerprint:', watcherFP
console.log 'Client fingerprint', clientFP

await new Vault Config.vault, watcherFP, clientFP, defer vault
console.log 'Connected to vault'

watchers = {}

processSettings = (settings) ->
  console.log 'New settings:', settings
  Object.keys(settings.files).map (key) ->
    p = path.normalize key
    watchers[p] = extend settings.files[key], {}
    watchers[p].differ = new Diff p
    watchers[p].policies = watchers[p].policies.map (policy) ->
      policy.params.filename = p
      policy.sandbox = new Sandbox policy
      policy

  watcher = chokidar.watch Object.keys watchers
  watcher
    .on 'ready', () =>
      console.log 'Ready for changes!'
    .on 'change', (path, stats) =>
      file = watchers[path]
      await file.differ.update defer changes
      console.log "Change detected in #{path}"

      await cryptoBox.encrypt JSON.stringify(changes), defer err, encrypted
      await vault.save 'diffs', {creator: watcherFP, reader: clientFP, content: encrypted}

      for policy in file.policies
        console.log "Must enforce policy #{policy.sandbox.name}"
        policy.sandbox.send changes


vault.watch 'settings', {reader: watcherFP}, (settings) =>
  if settings
    processSettings settings

module.exports = app
