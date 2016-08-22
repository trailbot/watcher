'use strict'

Config = require './Config'
inquirer = require 'inquirer'
colors = require 'colors'
fs = require 'fs'

class Exporter

  constructor : ->
    unless Config.watcher_pub_key
      console.error 'This watcher is not yet configured. Please run this command first:'.red
      console.error 'sudo npm run-script configure'.cyan.bold
      return

    if process.argv[2]
      console.log "indice argv ", process.argv[2]
      await fs.writeFile process.argv[2], Config.watcher_pub_key, {encoding: 'utf8'}, defer err, res
      if err
        console.error 'Invalid output path: directory does not exist or writing to it is not allowed.'.red
      else
        console.log "Public key succesfully exported to #{process.argv[2]}".green
      return


    inquirer.prompt [
      name: 'output'
      message: "What method do you want to use for exporting your watcher's public key?"
      type: 'list'
      choices: [
        name: 'Print to screen'
        value: 'stdio'
      ,
        name: 'Write to filesystem'
        value: 'filesystem'
      ]
    ]
    .then ({output}) ->
      if output is 'stdio'
        # console.log Config.watcher_pub_key
        console.log "\nSentence:"
        console.log "#{Config.sentence}\n".cyan.bold
      else if output is 'filesystem'
        inquirer.prompt [
          name: 'path'
          message: 'Path of the output file:'
          type: 'input'
          default: './trailbot_watcher.pub.asc'
          validate: (path) ->
            new Promise (next) ->
              console.log
              await fs.writeFile path, Config.sentence, {encoding: 'utf8'}, defer err, res
              # await fs.writeFile path, Config.watcher_pub_key, {encoding: 'utf8'}, defer err, res
              next err && 'Invalid output path: directory does not exist or writing permission is not granted.' || true
        ]
        .then ({path}) ->
            console.log "Public key succesfully exported to #{path}".green
      else if output is 'scp'
        console.error 'Copying to another system over scp is planned but not yet supported.'.bgRed
        console.error 'Please select another method.'.bgRed
        setTimeout Exporter, 2000

new Exporter()
