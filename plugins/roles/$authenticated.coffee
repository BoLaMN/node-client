module.exports = ->

  @decorator 'ACL', (ACL) ->

    ACL.AUTHENTICATED = '$authenticated'

    ACL.registerResolver ACL.AUTHENTICATED, (role, context, callback = ->) ->
      if not context
        return callback false

      callback context.isAuthenticated()

    ACL