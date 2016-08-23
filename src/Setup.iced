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


class Configure

  constructor : ->
    @localStorage = new require 'node-localstorage'
      .LocalStorage(Config.local_storage)
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
      name: 'vault'
      message: "Type the domain and port of the vault server you want to use"
      type: 'input'
      #TODO set i.t back to production 'vault.trailbot.io:8443'
      default: 'localhost:8443'
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
      @localStorage.setItem 'watcher_priv_key', watcher_priv_key
      @localStorage.setItem 'watcher_pub_key', watcher_pub_key
      @localStorage.setItem 'vault', answers.vault

      await new Crypto watcher_priv_key, null, defer cryptoBox
      watcherFP = cryptoBox.watcherKey.get_pgp_fingerprint().toString('hex')

      exchange =
        channel: @generateChannel()
        creator: watcherFP
        watcher: watcher_pub_key
        expires: @getExpirationDate()

      sentence = pgpWordList.toWords(exchange.channel).toString().replace(/,/g,' ')

      @done = true
      @alert "Now install Trailbot Client in your computer and start the setup wizard." , true
      @alert "The following 8 words will be required by the Trailbot Client:"
      @alert "#{sentence}".cyan.bold, true

      await new Vault this, answers.vault, watcherFP, defer vault
      vault.save 'exchange', exchange
      @alert "Waiting for confirmation from Trailbot Client..." , true
      vault.watch 'exchange', exchange, (change) =>
        # if change is null the document was deleted
        process.exit 0 unless change
        if change && change.client
          @localStorage.setItem 'client_pub_key', change.client
          vault.remove 'exchange', [change], (res) =>
            console.log "file deleted"







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
    crypto.createHash('md5').update(word).digest("hex").substr(0, 16)

  getExpirationDate : () =>
    now = new Date()
    now.setMinutes(now.getMinutes() + 5)
    now.toString()



new Configure()
