module.exports = (InvalidArgumentError, jwt) ->

  ###*
  # Handle client credentials grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.4.2
  ###

  @login = (providerId, clientId, request, response) ->
    query =
      where: 
        clientId: clientId
        providerId: providerId 
        enabled: true
      include: [ 'provider' ]

    @findOne(query).then ({ properties, provider }) =>
      protocol = @initializeProtocol provider, properties
      state = @createStateToken request
      type = protocol.handle request

      protocol[type] response, state
        .then (result) ->
          if type is 'request'
            response.redirect result
          else result

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

