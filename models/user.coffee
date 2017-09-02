module.exports = (InvalidArgumentError, InvalidRequestError, debug) ->

  @::validateUser = (client) ->
    if not @applications
      throw new InvalidRequestError 'INVALIDCLIENT'

    debug "in validateUser validating application access (applications: #{ JSON.stringify @applications }, client: #{ JSON.stringify client })"

    valid = @applications.some (application) ->
      application.id is client.id

    debug "in validateUser validation: " + valid

    valid

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

  @login = (email, password) ->
    if not email
      throw new InvalidRequestError 'Missing parameter: `email`'

    if not validate.uchar email
      throw new InvalidRequestError 'Invalid parameter: `email`'

    if not password
      throw new InvalidRequestError 'Missing parameter: `password`'

    if not validate.uchar password
      throw new InvalidRequestError 'Invalid parameter: `password`'

    debug "in getUser (email: #{ email })"

    @findOne
      where: 
        email: email
      include: [ 
        { relation: 'groups', scope: { include: [ 'roles' ] } }, 
        'roles', 'applications' 
      ]
    .then (user) ->
      debug "in validatePassword (validating password for user: #{ JSON.stringify(user) })"

      if not user or not bcrypt.compareSync password, user.password
        throw new InvalidRequestError 'Invalid grant: user credentials are invalid'

      if not user or not user.validateUser client
        return throw new UnauthorizedClientError 'NOACCESS'
      
      roles = []

      if user.roles
        user.roles.forEach (role) ->
          role.push role.name

      if user.groups
        user.groups.forEach (group) ->
          return unless group.roles

          group.roles.forEach (role) ->
            roles.push role.name

      debug "in createToken (token: #{ accessToken }, clientId: #{ client.id }, userId: #{ userId or client.userId }, expires: #{ accessTokenExpiresAt }, roles: #{ roles })"
      
      model = responseTypes[responseType]

      model.create 
        clientId: client.id
        roles: roles
        userId: client.userId
        appId: client.id
        

