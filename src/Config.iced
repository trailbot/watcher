fs = require 'fs'
{make_esc} = require 'iced-error'

Config = {}

Config.local_storage = '.localstorage'
Config.vault = 'localhost:8181' # TODO use production server URL
Config.policies_dir = './policies'

if process.env['DEV'] is 'true'
  console.log 'DEV MODE'
  Config.vault = 'localhost:8181'
  Config.watcher_priv_key = fs.readFileSync './keys/watcher.pgp', {encoding: 'utf8'}
  Config.watcher_pub_key = fs.readFileSync './keys/watcher.pgp', {encoding: 'utf8'}
  Config.client_pub_key = fs.readFileSync '../client/TrailBot_client.pub', {encoding: 'utf8'}

localStorage = new (require 'node-localstorage').LocalStorage(Config.local_storage)
settings = localStorage.getItem 'settings'

for key, val of settings
  Config[key] = val

if Config.vault? && Config.watcher_priv_key? && Config.client_pub_key?
  Config.ready = true

Config.header = """

    88888888888                  d8b 888 888888b.            888
        888                      Y8P 888 888  "88b           888
        888                          888 888  .88P           888
        888     888d888  8888b.  888 888 8888888K.   .d88b.  888888
        888     888P"       "88b 888 888 888  "Y88b d88""88b 888
        888     888     .d888888 888 888 888    888 888  888 888
        888     888     888  888 888 888 888   d88P Y88..88P Y88b.
        888     888     "Y888888 888 888 8888888P"   "Y88P"   "Y888

"""

module.exports = Config
