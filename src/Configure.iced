'use strict'

Config = require './Config'
inquirer = require 'inquirer'
colors = require 'colors'
fs = require 'fs'
os = require 'os'
kbpgp = require 'kbpgp'
progress = require 'progress'

class Configure

  constructor : ->
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
      default: './client_key.pub'
      validate: (path) ->
        new Promise (next) ->
          fs.readFile path, {encode: 'utf8'}, (err, content) ->
            next err or true
    ,
      name: 'vault'
      message: "Type the FQDN of the vault server you want to use"
      type: 'input'
      default: 'vault.trailbot.io'
    ]
    .then (answers) =>
      @alert "Ok, we are now generating a new PGP keypar for this watcher.", true
      @alert "This may take up to a couple of minutes. Please wait while magic happens...\n "
      @progress = new progress '  Generating... [:bar] :percent'.bold,
        total: 330
        complete: '='
        incomplete: ' '
        width: 60
      await @keygen answers.hostname, defer priv, pub
      @alert "Done! The watcher is now completely set up.", true

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


new Configure()
