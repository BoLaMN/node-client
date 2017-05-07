module.exports = ->

  @decorator 'ACL', (ACL) ->

    ACL.UNAUTHENTICATED = '$unauthenticated'

    ACL.registerResolver ACL.UNAUTHENTICATED, (role, context, callback = ->) ->
      if not context
        return callback false

      callback not context.isAuthenticated()

    ACL