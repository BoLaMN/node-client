module.exports = (UnauthorizedClientError, InvalidRequestError, debug, Role, ApplicationProvider, Application, AccessToken, AuthorizationCode) ->

  @::connect = (provider, auth, info) ->
    data =
      lastProvider: provider.id

    identity =
      provider: provider.id
      protocol: provider.protocol
      credentials: auth
      profile: info

    if provider.refresh_userinfo or 
       not user.name or 
       user.name.trim() is ''
      
      remap provider.mapping, info, data

    fns = [
     @updateAttributes data
     @identities.create identity
    ]

    Promise.all fns

  @lookup = (email, providerId) ->

    @findOne       
      where:
        email: email
      include: [
        {
          relation: 'identities'
          scope: 
            where: 
              provider: providerId
        }
        {
          relation: 'groups'
          scope: { include: [ 'roles' ] }
        }
        'roles', 'applications'
      ]

  ###*
  # Retrieve the user from the model using a email/password combination.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.3.2
  ###

  @login = (clientId, grantType, responseType, request, response) ->

    switch grantType
      when 'custom'
        { providerId } = request.param 'providerId'

        return ApplicationProvider.login providerId, clientId, request, response 
      when 'client_credentials'
        { clientSecret, clientKey } = request.param 'clientSecret', 'clientKey'

        return Application.login clientId, clientSecret, clientKey, responseType
      when 'password'
        { email, password } = request.param 'email', 'password'

        return @authenticate clientId, email, password, responseType

  @getGroupsAndRoles = (instance) =>
    @include instance, [
      {
        relation: 'groups'
        scope: { include: [ 'roles' ] }
      }
      'roles'
    ]
    .then (included) ->
      included[0] 

  @createToken = (clientId, responseType) -> 
    responseTypes =
      code: AuthorizationCode
      token: AccessToken

    model = responseTypes[responseType]

    (instance) ->
      roles = Role.groupByName instance 

      debug "in createToken (clientId: #{ clientId }, userId: #{ instance.id }, roles: #{ roles })"

      model.create 
        clientId: clientId
        roles: roles
        userId: instance.id

  @authenticate = (clientId, email, password, responseType) ->
    if not email
      throw new InvalidRequestError 'Missing parameter: `email`'

    if not validate.uchar email
      throw new InvalidRequestError 'Invalid parameter: `email`'

    if not password
      throw new InvalidRequestError 'Missing parameter: `password`'

    if not validate.uchar password
      throw new InvalidRequestError 'Invalid parameter: `password`'

    debug "in getUser (email: #{ email })"

    checkUserHasClient = (user) ->
      user.applications.exists clientId 
        .then (exists) ->
          if not exists
            return throw new InvalidRequestError 'INVALIDCLIENT'
          user

    comparePassword = (user) ->
      new Promise (resolve, reject) =>
        if not user.password or not password
          return reject new InvalidRequestError 'Invalid grant: user credentials are invalid'

        bcrypt.compare password, user.password, (err, match) ->
          if err or not match
            return reject new InvalidRequestError 'Invalid grant: user credentials are invalid'

          resolve user

    @findOne where: email: email
      .tap (user) ->
        if not user 
          throw new InvalidRequestError 'Invalid grant: user credentials are invalid'
      .then checkUserHasClient
      .then comparePassword
      .then getGroupsAndRoles
      .then createToken clientId, responseType

