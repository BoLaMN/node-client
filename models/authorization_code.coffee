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

  @revokeAuthorizationCode = (id) ->
    debug "in revokeAuthorizationCode (code: #{ id })"

    query =
      where: { id }

    options =
      remove: true

    @findAndModify query, null, options
      .then (code) ->
        if not code
          throw new InvalidGrantError 'Invalid grant: authorization code is invalid'

        if not (code.expiresAt instanceof Date)
          throw new ServerError 'Server error: `expiresAt` must be a Date instance'

        if code.expiresAt >= new Date
          throw new ServerError 'Server error: authorization code should be expired'

        code
