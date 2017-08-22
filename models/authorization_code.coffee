module.exports = (Model) ->

  ###*
  # Handle authorization code grant.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.1.3
  ###

  Model.handleGrant = (request, response) ->
    if not request
      throw new InvalidArgumentError 'REQUEST'

    Promise.bind this
      .then ->
        @getAuthorizationCode request.body.code
      .tap (code) ->
        if code.client.id != @client.id
          throw new InvalidGrantError 'Invalid grant: authorization code is invalid'

        code.validateRedirectUri request.body.redirect_uri or request.query.redirect_uri
      .then (code) ->
        @revokeAuthorizationCode code.id

  ###*
  # Get the authorization code.
  # {code} body
  ###

  Model.getAuthorizationCode = (code) ->
    if not code
      throw new InvalidRequestError 'Missing parameter: `code`'

    if not validate.vschar code
      throw new InvalidRequestError 'Invalid parameter: `code`'

    #client = @client

    debug "in getAuthorizationCode (code: #{ code })"

    @findById code
      .then (code) ->
        if not code
          throw new InvalidGrantError 'Invalid grant: authorization code is invalid'

        if not code.client
          throw new ServerError 'Server error: `getAuthorizationCode()` did not return a `client` object'

        if not code.user
          throw new ServerError 'Server error: `getAuthorizationCode()` did not return a `user` object'

        if not (code.expiresAt instanceof Date)
          throw new ServerError 'Server error: `expiresAt` must be a Date instance'

        if code.expiresAt < new Date
          throw new InvalidGrantError 'Invalid grant: authorization code has expired'

        if code.redirectUri and not validate.uri code.redirectUri
          throw new InvalidGrantError 'Invalid grant: `redirect_uri` is not a valid URI'

        code

  ###*
  # Validate the redirect URI.
  #
  # "The authorization server MUST ensure that the redirect_uri parameter is
  # present if the redirect_uri parameter was included in the initial
  # authorization request as described in Section 4.1.1, and if included
  # ensure that their values are identical."
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.1.3
  ###

  Model::validateRedirectUri = (redirectUri) ->
    if not @redirectUri
      return

    #redirectUri = request.body.redirect_uri or request.query.redirect_uri

    if not validate.uri(redirectUri)
      throw new InvalidRequestError 'Invalid request: `redirect_uri` is not a valid URI'

    if redirectUri != code.redirectUri
      throw new InvalidRequestError 'Invalid request: `redirect_uri` is invalid'

    return

  ###*
  # Revoke the authorization code.
  #
  # "The authorization code MUST expire shortly after it is issued to mitigate
  # the risk of leaks. [...] If an authorization code is used more than once,
  # the authorization server MUST deny the request."
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.1.2
  ###

  Model.revokeAuthorizationCode = (id) ->
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
