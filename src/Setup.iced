'use strict'

Config = require './Config'
Crypto = require './Crypto'
inquirer = require 'inquirer'
colors = require 'colors'
fs = require 'fs'
os = require 'os'
kbpgp = require 'kbpgp'
progress = require 'progress'
pgpWordList = require('pgp-word-list-converter')()
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
      default: 'vault.trailbot.io:8443'
    ]
    .then (answers) =>
      @alert "Ok, we are now generating a new PGP keypar for this watcher.", true
      @alert "This may take up to a couple of minutes. Please wait while the magic happens...\n "
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

      @done = true
      console.log '\n'

      await new Vault this, answers.vault, watcherFP, defer vault
      await vault.save 'exchange', exchange, defer {id}
      process.exit 1 unless id
      exchange.id = id

      @alert "Now install Trailbot Client in your computer and start the setup wizard." , true
      @alert "The following 8 words will be required by Trailbot Client:"
      @alert "#{@channelToWords(exchange.channel)}".cyan.bold, true

      @alert "Waiting for confirmation from Trailbot Client..." , true
      vault.watch 'exchange', exchange.id, (change) =>
        # if change is null the document was deleted
        process.exit 0 unless change
        if change?.client
          @localStorage.setItem 'client_pub_key', change.client
          vault.remove 'exchange', [change.id], (res) =>
            console.log "file deleted"

      # every 5 minutes generate new words
      setInterval  =>
        exchange.channel = @generateChannel()
        exchange.expires = @getExpirationDate()
        vault.replace 'exchange', exchange
        @alert "Time to get confirmation from Trailbot Client expired", true
        @alert "New words generated"
        @alert "#{@channelToWords(exchange.channel)}".cyan.bold, true
      , 300000




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

  channelToWords : (channel) =>
    pgpWordList.toWords(channel).toString().replace(/,/g,' ')



new Configure()
