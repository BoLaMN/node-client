module.exports = (InvalidArgumentError, jwt) ->

  ###*
  # Handle client credentials grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.4.2
  ###

  @login = (clientId, providerId, request, response, responseType) ->
    
    query =
      where: 
        clientId: clientId
        providerId: providerId 
        enabled: true
      include: [ 'provider', 'application' ]

    connect = (provider, info) ->
      (user) ->
        data =
          lastProvider: provider.id

        identity =
          provider: provider.id
          protocol: provider.protocol
          profile: info

        if provider.refresh_userinfo or 
           not user.name or 
           user.name.trim() is ''
          
          remap provider.mapping, info, data

        fns = [
         user.updateAttributes data
         user.identities.create identity
        ]

        Promise.all(fns).then -> user

    checkUserHasClient = (user) ->
      user.applications.exists clientId 
        .then (exists) ->
          if not exists
            return throw new InvalidRequestError 'INVALIDCLIENT'
          user

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

      debug "in createToken (clientId: #{ clientId }, userId: #{ instance.id }, roles: #{ roles })"

      model.create 
        clientId: clientId
        roles: roles
        userId: instance.id

    @findOne(query).then ({ properties, provider, application }) =>
      protocol = @initializeProtocol provider, properties
      state = @createStateToken request
      type = protocol.handle request

      lookup = (info) ->
        application.users.find   
          where:
            email: info.email
        .tap (user) ->
          if not user 
            throw new InvalidRequestError 'Invalid grant: user credentials are invalid'
        .then connect provider, info
        .then checkUserHasClient
        .then getGroupsAndRoles
        .then createToken

      protocol[type] response, state
        .then (info) ->
          if type is 'request'
            response.redirect info
          else 
            lookup info

  @::initializeProtocol = (provider, properties) ->
    protocolPath = path.join __dirname, '..', 'protocol-types', provider.protocolId

    try
      protocol = require protocolPath
    catch e
      console.error e

    if not protocol
      throw new Error 'No strategy defined for provider \'' + provider.id + '\''

    new protocol provider, properties

  @::createStateToken = (request) ->
    params = [
      'client_id'
      'response_type'
      'grant_type'
      'provider'
      'callback_uri'
      'scope'
    ]

    stateParams = request.param params...

    jwt.sign stateParams, 'xxxxx'

