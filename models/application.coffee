module.exports = (InvalidGrantError, debug, AccessToken, AuthorizationCode, Role) ->

  @login = (clientId, clientSecret, clientKey, responseType) ->
    
    query =
      where: 
        id: clientId

    compareKeys = (client) ->
      debug "in validateClient (key: #{ client.key }, secret: #{ client.secret }, , clientSecret: #{ clientSecret }, clientKey: #{ clientKey }))"

      if client.secret isnt clientSecret or client.key isnt clientKey
        throw new InvalidGrantError 'Invalid grant: client credentials are invalid'

      client

    getGroupsAndRoles = (instance) =>
      @include instance, [
        {
          relation: 'groups'
          scope: { include: [ 'roles' ] }
        }
        'roles'
      ]
      .then (included) ->
        included[0] 

    responseTypes =
      code: AuthorizationCode
      token: AccessToken

    model = responseTypes[responseType]

    createToken = (instance) ->
      roles = Role.groupByName instance 

      debug "in createToken (clientId: #{ instance.id }, userId: #{ instance.userId }, roles: #{ roles })"

      model.create 
        clientId: clientId
        roles: roles
        userId: instance.userId
        appId: instance.id

    @findOne query
      .tap (client) ->
        if not client
          throw new InvalidClientError 'CLIENTCREDS'
      .then compareKeys
      .then getGroupsAndRoles
      .then createToken
