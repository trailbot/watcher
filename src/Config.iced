Config = {}

if process.env['DEV'] is true
  console.log 'DEV MODE'
  Config =
    mothership : 'localhost:10000'

module.exports = Config
