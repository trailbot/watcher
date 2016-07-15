{make_esc} = require 'iced-error'

fs = require 'fs'
kbpgp = require 'kbpgp'
extend = require('util')._extend
{Literal} = require '../node_modules/kbpgp/lib/openpgp/packet/literal'

class Crypto
  constructor : (watcherKeyPath, clientKeyPath, cb) ->
    esc = make_esc (err) -> console.error "[CRYPTO] #{err}"

    await fs.readFile clientKeyPath, {encoding: 'utf8'}, esc defer clientArmored
    await fs.readFile watcherKeyPath, {encoding: 'utf8'}, esc defer watcherArmored
    mKey = {armored: clientArmored}
    wKey = {armored: watcherArmored}
    await kbpgp.KeyManager.import_from_armored_pgp mKey, esc defer @clientKey
    await kbpgp.KeyManager.import_from_armored_pgp wKey, esc defer @watcherKey
    if @watcherKey.is_pgp_locked()
      await @watcherKey.unlock_pgp { passphrase: '' }, esc defer()

    @ring = new kbpgp.keyring.KeyRing
    for km in [@clientKey, @watcherKey]
      @ring.add_key_manager km

    cb this

  encrypt : (data, filename, cb) =>
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

  decrypt : (data, cb) =>
    esc = make_esc (err) -> console.error "[CRYPTO] #{err}"

    params =
      keyfetch: @ring
      armored: data.content
    await kbpgp.unbox params, esc defer literals
    delete data.content
    cb extend data, JSON.parse literals[0].toString()

module.exports = Crypto

