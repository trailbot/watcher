Config = {}

if process.env['DEV'] is 'true'
  console.log 'DEV MODE'
  Config.vault = 'localhost:8181'
  Config.watcher_key = './keys/watcher.pgp'
  Config.client_key = './keys/client.pgp'
  Config.policies_dir = './policies'

module.exports = Config
