url = require 'url'
path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'
npm = require 'npm'
vm = require 'vm'
Config = require './Config'

class Sandbox
  constructor : (repo, cb) ->
    # Set policy uri, ref, name and path
    @uri = repo.uri
    @ref = repo.ref or 'master'
    @lang = repo.lang or 'javascript'
    @ext = {
      'javascript': 'js'
      'coffeescript': 'coffee'
      'icedcoffeescript': 'iced'
    }[@lang]
    @queue = []
    @ready = false

    @name = url.parse(@uri).pathname.slice(1).replace(/\.git/g, '')
    if @ref isnt 'master'
      @name += "/#{ref}"
    @path = path.normalize "#{Config.policies_dir}/#{@name}"
    @abs = path.resolve @path
    #console.log @path, @abs

    # Make sure that path exists
    await mkdirp @path, defer err
    # Pull repository contents
    await @pull defer()
    # Install dependencies
    await @install defer npmData
    console.log "[NPM] Installed #{npmData.length} packages"
    # Retrieve code and compile to JS
    await fs.readFile "#{@path}/main.#{@ext}", 'utf8', defer err, code
    code = @toJS code
    # Start virtualization
    @virtualize code, repo.params

    cb and cb this

  pull : (cb) ->
    console.log "[SANDBOX] Pulling repository contents from #{@uri}"
    @git = require('simple-git')(@path).init()
    await @git.getRemotes 'origin', defer err, remotes
    for remote in remotes
      @git.removeRemote(remote.name) if remote.name.length > 0
    @git
      .addRemote('origin', @uri)
      .pull('origin', @ref)
      .checkout(@ref)
      .then cb

  toJS : (code) ->
    switch @lang
      when 'javascript'
        code
      when 'coffeescript'
        require('coffee-script').compile code, {header: false, bare: true}
      when 'icedcoffeescript'
        require('iced-coffee-script').compile code, {header: false, bare: true}

  install : (cb) =>
    console.log '[SANDBOX] Installing dependencies...'
    await fs.readFile "#{@abs}/package.json", 'utf8', defer err, json
    deps = Object.keys JSON.parse(json).dependencies
    await npm.load {prefix: @abs}, defer err
    await npm.commands.install deps, defer err, data
    cb data

  virtualize : (code, params) =>
    console.log '[SANDBOX] Virtualizing...'
    @vm = vm.createContext
      require: (mod) =>
        try
          require mod
        catch e
          require "#{@abs}/node_modules/#{mod}"
      console:
        log: (first, others...) =>
          console.log "[POLICY][#{@name}]:\n> #{first}", others...
      module: {}
      iced: require('iced-coffee-script').iced
    vm.runInContext code, @vm,
      displayErrors: true
    vm.runInContext "policy = new this.module.exports(#{JSON.stringify(params)})", @vm

    @ready = true
    for {o, p} in @queue
      @send o, p
    @queue = []

  send : (o, p) =>
    if @ready
      if @vm?.module?.exports?
        vm.runInContext "policy.receiver(#{JSON.stringify(o)}, #{JSON.stringify(p)})", @vm
    else
      console.log "[SANDBOX] #{@name or @uri} is not ready yet, queuing event (#{@queue.length + 1})"
      @queue.push {o, p}

module.exports = Sandbox
