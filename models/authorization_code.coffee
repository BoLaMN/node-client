module.exports = (InvalidRequestError, InvalidGrantError, ServerError, debug) ->

  ###*
  # Handle authorization code grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.1.3
  ###

  @::validateGrant = (redirectUri) ->
    if not @redirectUri
      return

    #redirectUri = request.body.redirect_uri or request.query.redirect_uri

    if not validate.uri redirectUri
      throw new InvalidRequestError 'Invalid request: `redirect_uri` is not a valid URI'

    if redirectUri isnt @redirectUri
      throw new InvalidRequestError 'Invalid request: `redirect_uri` is invalid'

    true

  ###*
  # Revoke the authorization code.
  #
  # "The authorization code MUST expire shortly after it is issued to mitigate
  # the risk of leaks. [...] If an authorization code is used more than once,
  # the authorization server MUST deny the request."
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.1.2
  ###

  @::revoke = (clientId) ->
    debug "in revokeAuthorizationCode (code: #{ @id })"

    expireAt = new Date
    expireAt.setSeconds expireAt.getSeconds() - 5 * 60

    query =
      where:
        id: @id
        used: false
        clientId: clientId
        createdAt:
          gte: expiredAt
      include: [ 'client', 'user' ]

    $set =
      used: true

    options =
      new: false

    @findAndModify query, { $set }, options
