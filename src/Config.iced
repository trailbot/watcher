fs = require 'fs'
{make_esc} = require 'iced-error'
colors = require 'colors'

Config = {}

Config.local_storage = '.localstorage'
Config.vault = 'vault.trailbot.io:8443'
Config.policies_dir = './policies'
Config.secure = true

if process.env['DEV'] is 'true'
  console.log 'DEV MODE'
  Config.vault = 'localhost:8443'
  Config.secure = false

localStorage = new (require 'node-localstorage').LocalStorage(Config.local_storage)
settings = localStorage._metaKeyMap

for key of settings
  Config[key] = localStorage.getItem key

if Config.vault? && Config.watcher_priv_key? && Config.client_pub_key?
  Config.ready = true

Config.header = "888888888888888888b.        d8888 88888 888     " + "888888b.   .d88888b. 88888888888".red +
"\n    888    888   Y88b      d88888  888  888     " + "888  \"88b d88P\" \"Y88b    888    ".red +
"\n    888    888    888     d88P888  888  888     " + "888  .88P 888     888    888    ".red +
"\n    888    888   d88P    d88P 888  888  888     " + "8888888K. 888     888    888    ".red +
"\n    888    8888888P\"    d88P  888  888  888     " + "888  \"Y88b888     888    888    ".red +
"\n    888    888 T88b    d88P   888  888  888     " + "888    888888     888    888    ".red +
"\n    888    888  T88b  d8888888888  888  888     " + "888   d88PY88b. .d88P    888    ".red +
"\n    888    888   T88bd88P     888 88888 88888888" + "8888888P\"  \"Y88888P\"     888".red +
"\n"

module.exports = Config
