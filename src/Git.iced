path = require 'path'
NodeGit = require 'nodegit'

class Git
  constructor : () ->
    @repoPath = path.resolve './repo'
    await NodeGit.Repository.open @repoPath, defer err, @repo

  commit : () ->
    await @repo.index defer err, index
    await index.addByPath 'system.log', defer err
    # await index.addAll null, null, null, null, defer err
    console.log err
    index.write()
    await index.writeTree defer err, oid
    await NodeGit.Reference.nameToId @repo, 'HEAD', defer err, head
    await @repo.getCommit head, defer err, parent
    author = NodeGit.Signature.now "Author Name", "me@luisivan.net"
    committer = NodeGit.Signature.now "Commiter Name", "me@luisivan.net"

    await @repo.createCommit 'HEAD', author, committer, 'Log change', oid, [parent], defer err, commitId
    await @repo.getRemote 'origin', defer err, remote
    callbacks =
      credentials : (url, username) ->
        console.log 'Start'
        console.log NodeGit.Cred.sshKeyFromAgent username
        cred = NodeGit.Cred.sshKeyFromAgent username
        cred = NodeGit.Cred.sshKeyNew username, '/Users/user/.ssh/id_rsa.pub', '/Users/user/.ssh/id_rsa', ''
        console.log cred.hasUsername()
        console.log 'End'
        cred
    #await remote.connect NodeGit.Enums.DIRECTION.PUSH, callbacks, null, null, defer err
    #console.log err
    # console.log @repo.defaultSignature()
    await remote.push ["refs/heads/master:refs/heads/master"], {callbacks}, defer err
    console.log err
    console.log 'Success'


module.exports = Git
