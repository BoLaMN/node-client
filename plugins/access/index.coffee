module.exports = (app) ->

  app.module 'Access', [ ]

  .initializer ->

    @include './errors'
    @include './access-context'
    @include './principal'

    @decorator 'ACL', (ACL) ->
      ACL.resolvers = {}

      ###*
      # Add custom handler for roles.
      # @param {String} role Name of role.
      # @param {Function} resolver Function that determines if a principal is in the specified role.
      # Signature must be `function(role, context, callback)`
      ###

      ACL.registerResolver = (role, resolver) ->
        ACL.resolvers[role] = resolver
        return

      ACL
