RockSolidSocket = require 'rocksolidsocket'
MsgpackRPC = require 'msgpackrpc'

class Mothership
  constructor : (url, @cryptoBox) ->
    sock = new RockSolidSocket url
    @rpc = new MsgpackRPC 'mothership.1', sock

  send : (data) ->
    await @cryptoBox.encrypt data, defer err, enc
    @rpc.invoke 'log', [enc]

module.exports = Mothership
