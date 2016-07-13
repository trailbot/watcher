Config = {}

if process.env['DEV'] is 'true'
  console.log 'DEV MODE'
  Config.vault = 'localhost:8181'
  Config.watcher_key = './keys/watcher.pgp'
  Config.client_key = '../client/SEMPER_client.pub'
  Config.policies_dir = './policies'
  Config.local_storage = '.localstorage'

module.exports = Config
