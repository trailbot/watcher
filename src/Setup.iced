'use strict'

Config = require './Config'
Crypto = require './Crypto'
inquirer = require 'inquirer'
colors = require 'colors'
fs = require 'fs'
os = require 'os'
kbpgp = require 'kbpgp'
progress = require 'progress'
pgpWordList = require 'pgp-word-list-converter'
crypto = require 'crypto'
Vault = require './Vault'
localStorage = new require 'node-localstorage'
  .LocalStorage(Config.local_storage)

class Configure

  constructor : ->
    @done = false
    process.on 'exit', =>
      unless @done
        process.exitCode = 1

    console.log Config.header.bold

    inquirer.prompt [
      name: 'hostname'
      message: "Choose a name for this watcher"
      type: 'input'
      default: os.hostname()
    ,
      name: 'clientKey'
      message: "Type the route for the client's public key"
      type: 'input'
      default: './trailbot_client.pub.asc'
      validate: (path) ->
        new Promise (next) ->
          fs.readFile path, {encode: 'utf8'}, (err, content) ->
            next err or true
    ,
      name: 'vault'
      message: "Type the FQDN and port of the vault server you want to use"
      type: 'input'
      default: 'vault.trailbot.io:8443'
    ]
    .then (answers) =>
      @alert "Ok, we are now generating a new PGP keypar for this watcher.", true
      @alert "This may take up to a couple of minutes. Please wait while magic happens...\n "
      @progress = new progress '  Generating... [:bar] :percent'.bold,
        total: 330
        complete: '='
        incomplete: ' '
        width: 50
      await @keygen answers.hostname, defer watcher_priv_key, watcher_pub_key
      await fs.readFile answers.clientKey, {encode: 'utf8'}, defer err, client_pub_key
      localStorage.setItem 'watcher_priv_key', watcher_priv_key
      localStorage.setItem 'watcher_pub_key', watcher_pub_key
      localStorage.setItem 'client_pub_key', client_pub_key
      localStorage.setItem 'vault', answers.vault

      # test

      await new Crypto watcher_priv_key, client_pub_key, defer cryptoBox
      watcherFP = cryptoBox.watcherKey.get_pgp_fingerprint().toString('hex')
      clientFP  = cryptoBox.clientKey.get_pgp_fingerprint().toString('hex')

      channel =
        channel: @generateChannel()
        creator: watcherFP
        watcher: watcher_pub_key
        expires: @getExpirationDate()

      await new Vault this, Config.vault, watcherFP, clientFP, defer vault
      console.log "about to save"
      await vault.save 'channel', channel, defer saved
      console.log saved

      localStorage.setItem 'channel', JSON.stringify channel, null, 4
      # end test


      @done = true

  keygen : (identity, cb, pcb) =>
    opts =
      userid: "#{identity} <watcher@#{identity}>"
      asp: new kbpgp.ASP
        progress_hook: =>
          @progress.tick() unless @progress.complete
    await kbpgp.KeyManager.generate_rsa opts, defer err, key
    await key.sign {}, defer err
    await key.export_pgp_private {}, defer err, priv
    await key.export_pgp_public {}, defer err, pub
    cb priv, pub

  alert : (text, breakBefore) ->
    b = breakBefore and "\n" or ""
    console.log "#{b}! ".green + text.bold

  generateChannel : () =>
    word = Math.random().toString(36).substring(2)
    crypto.createHash('md5').update(word).digest("hex").substr(0, 8)

  getExpirationDate : () =>
    now = new Date()
    now.setMinutes(now.getMinutes() + 5)
    now.toString()


new Configure()
