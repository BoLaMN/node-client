module.exports = (Model) ->

  ###*
  # Handle client credentials grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.4.2
  ###

  Model.handleGrant = (request, response) ->
    if not request
      throw new InvalidArgumentError 'REQUEST'

    { client_secret, client_key } = request.body

    debug "in validateClient (key: #{ @client.key }, secret: #{ @client.$secret }, , clientSecret: #{ client_secret }, clientKey: #{ client_key }))"

    if @client.$secret isnt client_secret or 
       @client.key isnt client_key
      throw new InvalidGrantError 'Invalid grant: client credentials are invalid'

    null