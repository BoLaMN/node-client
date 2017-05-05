debug = require('debug') 'security:acl'

module.exports = ->

  ###*
  # Check if a given principal is in the specified role.
  #
  # @param {String} role The role name.
  # @param {Object} context The context object.
  #
  # @callback {Function} callback Callback function.
  # @param {Error} err Error object.
  # @param {Boolean} isInRole True if the principal is in the specified role.
  ###

  @factory 'isInRole', (ACL) ->

    matchPrincipal = (context, acl) ->
      (context.principals).filter ({ type, id }) ->
        type is acl.principalType and id is acl.principalId

    (acl, context, callback) ->
      debug 'isInRole(): %s', acl.principalId
      context.debug()

      resolver = ACL.resolvers[acl.principalId]

      if resolver
        debug 'Custom resolver found for role %s', acl.principalId
        resolver acl.principalId, context, (result) ->
          debug 'isInRole() returns: ' + result
          return callback result
        return

      if context.principals.length is 0
        debug 'isInRole() returns: false'
        return callback false

      if matchPrincipal(context, acl).length
        debug 'isInRole() returns: true'
        return callback true

      callback false

