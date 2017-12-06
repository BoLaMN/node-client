module.exports = (InvalidGrantError, debug) ->

  @authenticate = (clientId, { clientSecret, clientKey }, responseType) ->

    where =
      id: clientId

    compareKeys = (client) ->
      debug "in validateClient (key: #{ client.key }, secret: #{ client.secret }, , clientSecret: #{ clientSecret }, clientKey: #{ clientKey }))"

      if client.secret isnt clientSecret or client.key isnt clientKey
        throw new InvalidGrantError 'Invalid grant: client credentials are invalid'

      client

    @findOne { where }
      .tap (client) ->
        if not client
          throw new InvalidClientError 'CLIENTCREDS'
      .then compareKeys

  @::initializeProtocol = (properties) ->
    protocolPath = path.join __dirname, '..', 'protocol-types', provider.protocolId

    try
      protocol = require protocolPath
    catch e
      console.error e

    if not protocol
      throw new Error 'No strategy defined for provider \'' + provider.id + '\''

    new protocol @, properties
