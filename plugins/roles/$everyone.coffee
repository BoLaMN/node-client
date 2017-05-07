module.exports = ->

  @decorator 'ACL', (ACL) ->

    ACL.EVERYONE = '$everyone'

    ACL.registerResolver ACL.EVERYONE, (role, context, callback) ->
      callback true

    ACL
