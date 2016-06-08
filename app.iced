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
secret = cryptoBox.watcherKey.primary.key.priv.x.toString(16)
console.log 'Secret:', secret
await new Vault Config.vault, secret, defer vault
console.log 'Connected to vault'

await vault.getOne 'settings', defer settings
console.log 'Settings:', settings

if settings
  vault.remove 'settings', [settings.id]

console.log 'Creating new settings'
vault.save 'settings', {
  secret: secret,
  observed:
    './syslog':
      policies: [
        uri: 'https://github.com/semper-policies/copier.git'
        language: 'coffeescript'
        params:
          copyTo: './copy.log'
      ,
#        uri: 'https://github.com/semper-policies/mailer.git'
#        language: 'coffeescript'
#        params:
#          from: 'support@stampery.com'
#          to: 'adansdpc@waalt.com'
      ]
}

observed = {}
Object.keys(settings.observed).map (key) ->
  p = path.normalize key
  observed[p] = extend settings.observed[key], {}
  observed[p].differ = new Diff p
  observed[p].policies = observed[p].policies.map (policy) ->
    policy.params.filename = p
    policy.sandbox = new Sandbox policy
    policy

console.log observed

watcher = chokidar.watch Object.keys observed
watcher
  .on 'ready', () =>
    console.log 'Ready for changes!'
  .on 'change', (path, stats) =>
    file = observed[path]
    await file.differ.update defer changes
    console.log "Change detected in #{path}"

    await cryptoBox.encrypt JSON.stringify(changes), defer err, encrypted
    await vault.save 'diffs', {sig: encrypted}

    for policy in file.policies
      console.log "Must enforce policy #{policy.sandbox.name}"
      policy.sandbox.send changes

module.exports = app
