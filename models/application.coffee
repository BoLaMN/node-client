module.exports = (InvalidGrantError, debug, AccessToken, AuthorizationCode) ->

  ###*
  # Handle client credentials grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.4.2
  ###

  @::validateGrant = (clientSecret, clientKey) ->
    debug "in validateClient (key: #{ @client.key }, secret: #{ @client.$secret }, , clientSecret: #{ client_secret }, clientKey: #{ client_key }))"

    if @$secret isnt clientSecret or @key isnt clientKey
      throw new InvalidGrantError 'Invalid grant: client credentials are invalid'

    true

  @::login = (clientSecret, clientKey, responseType) ->
    
    responseTypes =
      code: AuthorizationCode
      token: AccessToken

    query =
      where: 
        id: @id
      include: [ 'owner', 'roles', 'groups' ]

    @findOne query
      .then (client) ->
        debug "in getClient (client: #{ JSON.stringify(client) })"

        if not client or not client.validateGrant clientSecret, clientKey
          throw new InvalidClientError 'CLIENTCREDS'

        roles = []

        if client.roles
          client.roles.forEach (role) ->
            role.push role.name

        if client.groups
          client.groups.forEach (group) ->
            return unless group.roles

            group.roles.forEach (role) ->
              roles.push role.name

        model = responseTypes[responseType]

        model.create 
          clientId: client.id
          roles: roles
          userId: client.userId
          appId: client.id
        
