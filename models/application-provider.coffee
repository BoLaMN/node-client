module.exports = (InvalidArgumentError, jwt) ->

  ###*
  # Handle client credentials grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.4.2
  ###

  @authenticate = (clientId, providerId, request, response, responseType) ->

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

    @findOne(query).then ({ properties, provider, application }) =>
      protocol = provider.initializeProtocol properties
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

      protocol[type] response, state
        .then (info) ->
          if type is 'request'
            response.redirect info
          else
            lookup info

  @createStateToken = (request) ->
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

