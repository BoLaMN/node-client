module.exports = (UnauthorizedClientError, InvalidRequestError, debug) ->

  @login = (userId, clientId) ->

    query =
      where: 
        clientId: clientId
        userId: userId 
      include: [ 'user', 'application' ]

    @findOne(query).then ({ user, application }) =>
      debug "in validatePassword (validating password for user: #{ JSON.stringify(user) })"

      if not user or not bcrypt.compareSync password, user.password
        throw new InvalidRequestError 'Invalid grant: user credentials are invalid'

      if not user or not user.validateUser application
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

      model = responseTypes[responseType]

      model.create 
        clientId: application.id
        roles: roles
        userId: application.userId
        appId: application.id
      .tap (token) ->
        debug "in createToken (token: #{ token })"
      

