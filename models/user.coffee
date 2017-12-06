module.exports = (UnauthorizedClientError, InvalidRequestError, debug, Role, ApplicationProvider, Application, AccessToken, AuthorizationCode) ->

  ###*
  # Retrieve the user from the model using a email/password combination.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.3.2
  ###

  @login = (clientId, providerId, grantType, responseType, credentials, request, response) ->

    getGroupsAndRoles = (instance) =>
      model = instance.constructor

      @include [ instance ], [
        {
          relation: 'groups'
          scope: { include: [ 'roles' ] }
        }
        'roles'
      ]
      .then (included) ->
        included[0]

    createToken = (instance) ->
      roles = Role.groupByName instance

      debug "in createToken (clientId: #{ clientId }, userId: #{ instance.userId or instance.id }, roles: #{ roles })"

      token =
        clientId: clientId
        roles: roles
        userId: instance.userId or instance.id

      if instance.userId
        token.appId = instance.id

      @create token

    grantTypes =
      custom: ->
        ApplicationProvider.authenticate clientId, providerId, request, response
      client_credentials: ->
        Application.authenticate clientId, credentials
      password: =>
        @authenticate clientId, credentials

    responseTypes =
      code: AuthorizationCode
      token: AccessToken

    model = responseTypes[responseType]
    grant = grantTypes[grantType]

    grant()
      .then getGroupsAndRoles
      .then createToken

  @authenticate = (clientId, { email, password }, responseType) ->
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

    @findOne where: { email }
      .tap (user) ->
        if not user
          throw new InvalidRequestError 'Invalid grant: user credentials are invalid'
      .then checkUserHasClient
      .then comparePassword

  @remoteMethod 'login',
    description: 'authorize a user with email and password.'
    params:
      clientId:
        type: 'objectid'
        required: true
        source: 'query'
      providerId:
        type: 'objectid'
        required: false
        default: null
        source: 'query'
      grantType:
        type: 'string'
        required: true
        source: 'query'
      responseType:
        type: 'string'
        required: true
        source: 'query'
      credentials:
        type: 'object'
        required: false
        default: {}
        source: 'body'
      request:
        type: 'object'
        required: true
        source: 'req'
      response:
        type: 'object'
        required: true
        source: 'res'
    returns:
      arg: 'AccessToken'
      type: 'object'
      root: true
      description: 'The response body contains properties of the AccessToken created on login.\n' + 'Depending on the value of `include` parameter, the body may contain ' + 'additional properties:\n\n' + '  - `user` - `{User}` - Data of the currently logged in user. (`include=user`)\n\n'
    accessType: "EXECUTE"
    path: "/authenticate"
    method: 'post'
