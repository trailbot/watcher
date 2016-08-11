request = require 'request'

class Azure
  constructor : (@app) ->
    token = @stamperyToken()

    @app.defaults.policies.push
      name: 'Blockchain anchoring'
      uri: 'https://github.com/trailbot/stamper-policy'
      ref: 'master'
      lang: 'icedcoffeescript'
      params:
        secret: token
        proofsDir: '/var/proofs'

  stamperyToken : () =>
    (@app.localStorage.getItem 'stampery_token') or @stamperySignup()

  stamperySignup : () =>
    hostname = require('os').hostname()
    await request
      method: 'post'
      url: 'https://api-dashboard.stampery.com/trialToken'
      json: true
      data:
        email: @app.localStorage.getItem 'user_email'
        name: "Trailbot at #{hostname}"
        tags: ['trailbot', 'trial']
    , defer err, res

module.exports =
  azure: Azure
