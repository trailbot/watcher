{make_esc} = require 'iced-error'

fs = require 'fs'
kbpgp = require 'kbpgp'
{Literal} = require '../node_modules/kbpgp/lib/openpgp/packet/literal'

class Crypto
  constructor : (watcherKeyPath, clientKeyPath, cb) ->
    esc = make_esc (err) -> console.log "[CRYPTO] Error: #{err}"
    await fs.readFile watcherKeyPath, {encoding: 'utf8'}, esc defer watcherArmored
    await fs.readFile clientKeyPath, {encoding: 'utf8'}, esc defer clientArmored
    wKey = {armored: watcherArmored}
    mKey = {armored: clientArmored}
    await kbpgp.KeyManager.import_from_armored_pgp wKey, esc defer @watcherKey
    if @watcherKey.is_pgp_locked()
      await @watcherKey.unlock_pgp { passphrase: '' }, esc defer()
    await kbpgp.KeyManager.import_from_armored_pgp mKey, esc defer @clientKey
    cb this

  encrypt : (data, filename, cb) ->
    return setTimeout @encrypt.bind(this, data, cb), 500 if not @watcherKey

    params =
      encrypt_for : @clientKey
      sign_with : @watcherKey
      literals: [ new Literal
        format: kbpgp.const.openpgp.literal_formats.utf8
        filename: new Buffer(filename)
        date: kbpgp.util.unix_time()
        data: new Buffer(data)
      ]
    kbpgp.box params, cb

module.exports = Crypto

