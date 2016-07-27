fs = require 'fs'
{make_esc} = require 'iced-error'
colors = require 'colors'

Config = {}

Config.local_storage = '.localstorage'
Config.vault = 'vault.trailbot.io'
Config.policies_dir = './policies'

if process.env['DEV'] is 'true'
  console.log 'DEV MODE'
  Config.vault = 'localhost:8181'
  Config.watcher_priv_key = fs.readFileSync './trailbot_watcher.priv.asc', {encoding: 'utf8'}
  Config.watcher_pub_key = fs.readFileSync './trailbot_watcher.pub.asc', {encoding: 'utf8'}
  Config.client_pub_key = fs.readFileSync './trailbot_client.pub.asc', {encoding: 'utf8'}

localStorage = new (require 'node-localstorage').LocalStorage(Config.local_storage)
settings = localStorage._metaKeyMap

for key of settings
  Config[key] = localStorage.getItem key

if Config.vault? && Config.watcher_priv_key? && Config.client_pub_key?
  Config.ready = true

Config.header = "  88888888888 8888888b.         d8888 8888888 888      " + "888888b.    .d88888b.  88888888888 ".red +
"\n      888     888   Y88b       d88888   888   888      " + "888  \"88b  d88P\" \"Y88b     888     ".red +
"\n      888     888    888      d88P888   888   888      " + "888  .88P  888     888     888     ".red +
"\n      888     888   d88P     d88P 888   888   888      " + "8888888K.  888     888     888     ".red +
"\n      888     8888888P\"     d88P  888   888   888      " + "888  \"Y88b 888     888     888     ".red +
"\n      888     888 T88b     d88P   888   888   888      " + "888    888 888     888     888     ".red +
"\n      888     888  T88b   d8888888888   888   888      " + "888   d88P Y88b. .d88P     888     ".red +
"\n      888     888   T88b d88P     888 8888888 88888888 " + "8888888P\"   \"Y88888P\"      888".red +
"\n"

module.exports = Config
