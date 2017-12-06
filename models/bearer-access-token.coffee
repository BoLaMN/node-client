module.exports = (InvalidRequestError, debug) ->

  @getTokenFromRequest = ({ headers, query, body, method }) ->
    headerToken = headers.authorization
    queryToken = query.access_token
    bodyToken = body.access_token

    if not not headerToken + not not queryToken + not not bodyToken > 1
      return

    if headerToken
      return @getTokenFromRequestHeader headerToken

    if queryToken
      return @getTokenFromRequestQuery queryToken

    if bodyToken
      return @getTokenFromRequestBody method, headers['content-type'], bodyToken

    return

  ###*
  # Get the token from the request header.
  #
  # @see http://tools.ietf.org/html/rfc6750#section-2.1
  ###

  @getTokenFromRequestHeader = (token) ->
    matches = token.match /Bearer\s(\S+)/

    if not matches
      return

    @findById matches[1]

  ###*
  # Get the token from the request query.
  #
  # "Don't pass bearer tokens in page URLs:  Bearer tokens SHOULD NOT be passed in page
  # URLs (for example, as query string parameters). Instead, bearer tokens SHOULD be
  # passed in HTTP message headers or message bodies for which confidentiality measures
  # are taken. Browsers, web servers, and other software may not adequately secure URLs
  # in the browser history, web server logs, and other data structures. If bearer tokens
  # are passed in page URLs, attackers might be able to steal them from the history data,
  # logs, or other unsecured locations."
  #
  # @see http://tools.ietf.org/html/rfc6750#section-2.3
  ###

  @getTokenFromRequestQuery = (token) ->
    @findById token

  ###*
  # Get the token from the request body.
  #
  # "The HTTP request method is one for which the request-body has defined semantics.
  # In particular, this means that the "GET" method MUST NOT be used."
  #
  # @see http://tools.ietf.org/html/rfc6750#section-2.2
  ###

  @getTokenFromRequestBody = (method, type, token) ->
    if method is 'GET'
      throw new InvalidRequestError 'GETBODY'

    if type is 'application/x-www-form-urlencoded'
      throw new InvalidRequestError 'FORMENCODED'

    @findById token

