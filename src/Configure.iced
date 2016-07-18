'use strict'

Config = require './Config'
inquirer = require 'inquirer'
colors = require 'colors'
fs = require 'fs'
os = require 'os'

class Configure

  constructor : ->
    console.log Config.header.bold

    inquirer.prompt [
      name: 'hostname'
      message: 'Please choose a name for this watcher'
      type: 'input'
      default: os.hostname()
    ,
      name: 'clientKey'
      message: "Please type the route for the client's public key"
      default: './client_key.pub'
      filter: (path) ->
        new Promise (next) ->
          fs.readFile path, {encode: 'utf8'}, (err, content) ->
            next content || err && false
      validate: (content) ->
        new Promise (next) ->
          console.log content
    ]
    .then (answers) ->
      console.log answers


new Configure()
