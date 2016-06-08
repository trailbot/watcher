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
sec = cryptoBox.watcherKey.primary.key.priv.x.toString(16)
pub = cryptoBox.watcherKey.primary.key.pub.q.toString(16)
console.log 'My sec:', sec
console.log 'My pub', pub

await new Vault Config.vault, sec, pub, defer vault
console.log 'Connected to vault'

await vault.getOne 'settings', {reader: pub}, defer settings
console.log 'Old settings:', settings

if settings
  vault.remove 'settings', [settings.id]

console.log 'Creating new settings'
settings = {
  creator: pub,
  reader: pub,
  watchers:
    './syslog':
      policies: [
        uri: 'https://github.com/semper-policies/copier.git'
        language: 'coffeescript'
        params:
          copyTo: './copy.log'
      ]
}
vault.save 'settings', settings

watchers = {}
Object.keys(settings.watchers).map (key) ->
  p = path.normalize key
  watchers[p] = extend settings.watchers[key], {}
  watchers[p].differ = new Diff p
  watchers[p].policies = watchers[p].policies.map (policy) ->
    policy.params.filename = p
    policy.sandbox = new Sandbox policy
    policy

console.log watchers

watcher = chokidar.watch Object.keys watchers
watcher
  .on 'ready', () =>
    console.log 'Ready for changes!'
  .on 'change', (path, stats) =>
    file = watchers[path]
    await file.differ.update defer changes
    console.log "Change detected in #{path}"

    await cryptoBox.encrypt JSON.stringify(changes), defer err, encrypted
    await vault.save 'diffs', {sig: encrypted}

    for policy in file.policies
      console.log "Must enforce policy #{policy.sandbox.name}"
      policy.sandbox.send changes

module.exports = app
