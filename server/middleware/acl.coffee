
module.exports = (ServerError, AccessDeniedError, AccessContext, BearerAccessToken, MacAccessToken, UnauthorizedRequestError, OAuthError, InvalidTokenError, debug, opts = {}) ->
        
  getAccessType = (route) ->
    if route.accessType
      return route.accessType

    if route.method in [ 'get', 'head' ]
      return AccessContext.READ

  ###*
  # Get the token from the header or body, depending on the request.
  #
  # "Clients MUST NOT use more than one method to transmit the token in each request."
  #
  # @see https://tools.ietf.org/html/rfc6750#section-2
  ###

  getTokenFromRequest = (request) ->

    Promise.all [
      BearerAccessToken.getTokenFromRequest(request)
      MacAccessToken.getTokenFromRequest(request)
    ]
    .then ([ bearerToken, macToken ]) ->
      debug "in getTokenFromRequest (bearerToken: #{ bearerToken }, macToken: #{ macToken })"

      if not bearerToken and not macToken
        throw new UnauthorizedRequestError 'NOAUTH'

      bearerToken or macToken

  ###*
  # Get the access token from the model.
  ###

  getAccessToken = (instance) ->
    debug "in getAccessToken (token: #{ token }), unauthenticated, no access token."

    instance.then (accessToken) ->
      debug "in getAccessToken (accessToken: #{ JSON.stringify(accessToken) })"

      if not accessToken
        throw new InvalidTokenError 'Invalid token: access token is invalid'

      accessToken

  (req, res) ->
    { params, query, body, route } = req
    { method, name, model } = route

    modelId = params.id or body.id or query.id

    context = new AccessContext
      modelName: model.name
      modelId: modelId
      methodName: name
      accessType: getAccessType route

    success = (token) ->
      if not token
        return throw new AccessDeniedError 'NOACCESS'

      if not token.userId and not token.roles
        return throw new ServerError 'USEROBJECT'

      { createdAt } = token

      if createdAt and not createdAt instanceof Date
        throw new ServerError 'DATEINSTANCE'
      
      expiredAt = createdAt.setSeconds createdAt.getSeconds() - 14 * 24 * 3600

      if expiredAt and expiredAt < new Date     
        throw new InvalidTokenError 'EXPIRED'

      context.setToken token

      context.checkAccess()
        .then (allowed) ->
          if not allowed
            return throw new AccessDeniedError 'NOACCESS'

          token

    error = (e) ->
      if e instanceof UnauthorizedRequestError
        res.header 'WWW-Authenticate': 'Bearer realm="Service"'

      if not e instanceof OAuthError
        throw new ServerError e

      throw e
    
    context.checkAccess()
      .then (allowed) ->
        if allowed
          return Promise.resolve allowed

        getTokenFromRequest req
          .then getAccessToken
          .then success
          .catch error

