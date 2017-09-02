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
      protocol = @initializeProtocol provider.protocolId

      if not protocol
        throw new Error 'No strategy defined for provider \'' + providerId + '\''

      state = @createStateToken request

      new protocol provider, properties, @userModel
        .handle request, response, state

  @findProvider = (providerId) ->
    client = @client.toObject()

    id = request.params.provider or request.body.provider

    foundProvider = client.providers.filter (provider) ->
      provider.providerId is id

    if not foundProvider.length
      throw new InvalidArgumentError 'PROVIDER'

    foundProvider[0]

  @initializeProtocol = (providerId) ->
    protocolPath = path.join __dirname, '..', 'protocol-types', providerId

    try
      protocol = require protocolPath
    catch e
      console.error e

    protocol

  @createStateToken = ({ body, query }) ->
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

