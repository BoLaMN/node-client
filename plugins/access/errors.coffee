module.exports = ->

  @require
    StandardHttpError: 'standard-http-error'

  @factory 'OAuthError', (StandardHttpError) ->
    class OAuthError extends StandardHttpError
      constructor: (messageOrError, properties = {}) ->
        message = if messageOrError instanceof Error then messageOrError.message else messageOrError
        error = if messageOrError instanceof Error then messageOrError else null

        if error
          properties.inner = error

        super properties.code, message, properties

  @factory 'InvalidArgumentError', (StandardHttpError) ->
    class InvalidArgumentError extends StandardHttpError
      constructor: (message, properties = {}) ->
        messages =
          RESPONSE: 'Invalid argument: `response` must be an instance of Response'
          REQUEST: 'Invalid argument: `request` must be an instance of Request'
          SAVEAUTHCODE: 'Invalid argument: model does not implement `saveAuthorizationCode()`'
          GETCLIENT: 'Invalid argument: model does not implement `getClient()`'
          GETACCESSTOKEN: 'Invalid argument: model does not implement `getAccessToken()`'
          MODEL: 'MODEL'
          AUTHCODELIFE: 'Missing parameter: `authorizationCodeLifetime`'
          ACCESSLIFE: 'Missing parameter: `accessTokenLifetime`'
          REFRESHLIFE: 'Missing parameter: `refreshTokenLifetime`'
          HANDLE: 'Invalid argument: authenticateHandler does not implement `handle()`'
          VALIDSCOPE: 'Invalid argument: model does not implement `validateScope()`'
          AUTHSCOPEHEADER: 'Missing parameter: `addAuthorizedScopesHeader`'
          ACCPTSCOPEHEADER: 'Missing parameter: `addAcceptedScopesHeader`'
          QUERY: 'Missing parameter: `query`'
          HEADERS: 'Missing parameter: `headers`'
          METHOD: 'Missing parameter: `method`'
          CLIENT: 'Missing parameter: `user`'
          USER: 'CLIENT'
          CODE: 'Missing parameter: `code`'
          SCOPE: 'Invalid parameter: `scope`'
          REDIRECT: 'Missing parameter: `redirectUri`'
          ACCESSTOKEN: 'Missing parameter: `accessToken`'
          ACCESSTOKENEXPIRESAT: 'Invalid parameter: `accessTokenExpiresAt`'
          REFRESHTOKENEXPIRESAT: 'Invalid parameter: `refreshTokenExpiresAt`'
          PROVIDER: 'Invalid parameter: `provider`'

        properties.code ?= 500
        properties.name ?= 'invalid_argument'

        super properties.code, messages[message], properties

  ###*
  #
  # "The authorization server encountered an unexpected condition that prevented it from fulfilling the request."
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
  ###

  @factory 'ServerError', (OAuthError) ->
    class ServerError extends OAuthError
      constructor: (message, properties = {}) ->

        messages =
          ACCESSTOKEN: 'Server error: `getAccessToken()` did not return a `user` object'
          DATEINSTANCE: 'Server error: `expires` must be a Date instance'
          USEROBJECT: 'Server error: `handle()` did not return a `user` object'
          MISSINGGRANTS: 'Server error: missing client `grants`'
          INVALIDGRANTS: 'Server error: `grants` must be an array'
          NOTIMPL: 'Not implemented.'

        properties.code ?= 503
        properties.name ?= 'server_error'

        super messages[message], properties

  ###*
  #
  # "If the request lacks any authentication information (e.g., the client
  # was unaware that authentication is necessary or attempted using an
  # unsupported authentication method), the resource server SHOULD NOT
  # include an error code or other error information."
  #
  # @see https://tools.ietf.org/html/rfc6750#section-3.1
  ###

  @factory 'UnauthorizedRequestError', (OAuthError) ->
    class UnauthorizedRequestError extends OAuthError
      constructor: (message, properties = {}) ->
        messages =
          NOAUTH:  'Unauthorized request: no authentication given'
          NOACCESS: 'Access denied: user denied access to application'

        properties.code ?= 401
        properties.name ?= 'unauthorized_request'

        super messages[message], properties

  ###*
  #
  # "The resource owner or authorization server denied the request"
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
  ###

  @factory 'AccessDeniedError', (OAuthError) ->
    class AccessDeniedError extends OAuthError
      constructor: (message, properties = {}) ->
        messages =
          NOACCESS: 'Access denied: user denied access to application'

        properties.code ?= 400
        properties.name ?= 'access_denied'

        super messages[message], properties
