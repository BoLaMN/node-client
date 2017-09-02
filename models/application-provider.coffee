module.exports = (InvalidArgumentError, jwt, Application) ->

  ###*
  # Handle client credentials grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.4.2
  ###

  @::login = (providerId, clientId) ->

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

  @::createStateToken = ({ body, query }) ->
    stateParams = {}

    params = [
      'client_id'
      'response_type'
      'grant_type'
      'provider'
      'callback_uri'
      'scope'
    ]

    for param in params
      stateParams[param] = body[param] or query[param]

    jwt.sign stateParams, 'xxxxx'

