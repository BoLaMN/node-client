module.exports = (InvalidGrantError, debug) ->

  ###*
  # Handle client credentials grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.4.2
  ###

  @::validateGrant = (client_secret, client_key) ->
    debug "in validateClient (key: #{ @client.key }, secret: #{ @client.$secret }, , clientSecret: #{ client_secret }, clientKey: #{ client_key }))"

    if @client.$secret isnt client_secret or 
       @client.key isnt client_key
      throw new InvalidGrantError 'Invalid grant: client credentials are invalid'

    true