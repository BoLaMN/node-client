###*
# Module dependencies
###

url = require '../utils/url'
crypto = require 'crypto'

Promise = require "bluebird"
promisedRequest = require "request-promise"

{ extend } = require 'lodash'
{ ServerError } = require '../errors/server-error'

agent = 'Identity Manager/0.1'

###*
# OAuthStrategy
###

class OAuthStrategy
  constructor: (@provider, @client) ->
    for own key,value of @provider
      @[key] = value

    @name = @provider.id

    return

  ###*
  # Verifier
  ###

  verify: (request, auth, info) ->
    User = request.app.models.User

    Promise.bind this
      .then ->
        User.lookup info
      .then (user) ->
        User.connect user, @provider, auth, info


  ###*
  # Authorization Header Params
  # https://tools.ietf.org/html/rfc5849#section-3.5.1
  ###

  authorizationHeaderParams: (data) ->
    keys = Object.keys(data).sort()
    encoded = ''

    keys.forEach (key, i) ->
      encoded += key
      encoded += '="'
      encoded += @encodeOAuthData(data[key])
      encoded += '"'

      if i < keys.length - 1
        encoded += ', '
      return

    encoded

  ###*
  # Encode Data
  # https://tools.ietf.org/html/rfc5849#section-3.6
  ###

  encodeOAuthData: (data) ->
    # empty data
    if !data or data is ''
      ''
      # non-empty data
    else
      encodeURIComponent(data).replace(/\!/g, '%21').replace(/\'/g, '%27').replace(/\(/g, '%28').replace(/\)/g, '%29').replace /\*/g, '%2A'

  ###*
  # Timestamp
  ###

  timestamp: ->
    Math.round(Date.now() / 1000)

  nonce: (size) ->
    NCHARS = [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']

    res = []
    len = NCHARS.length

    i = 0

    while i < size
      pos = Math.floor(Math.random() * len)
      res[i] = NCHARS[pos]
      i++

    res.join ''

  ###*
  # Signature Base String URI
  # https://tools.ietf.org/html/rfc5849#section-3.4.1.1
  # https://tools.ietf.org/html/rfc5849#section-3.4.1.2
  ###

  signatureBaseStringURI: (uri) ->
    { protocol
      hostname
      pathname
      port } = url.parse uri, true

    if port
      if protocol is 'http:' and port != '80' or protocol == 'https:' and port != '443'
        port = ':' + port

    if !pathname or pathname == ''
      pathname = '/'

    [ protocol
      '//'
      hostname
      port
      pathname ].join ''

  ###*
  # Normalize Parameters
  # https://tools.ietf.org/html/rfc5849#section-3.4.1.3.2
  ###

  normalizeParameters: (data) ->
    encoded = []
    normalized = ''

    Object.keys(data).forEach (key) ->
      encoded[encoded.length] = [
        @encodeOAuthData(key)
        @encodeOAuthData(data[key])
      ]
      return

    encoded.sort (a, b) ->
      if a[0] == b[0] then (if a[1] < b[1] then -1 else 1) else if a[0] < b[0] then -1 else 1

    encoded.forEach (pair, i) ->
      normalized += pair[0]
      normalized += '='
      normalized += pair[1]

      if i < encoded.length - 1
        normalized += '&'

      return

    normalized

  ###*
  # Signature Base String
  # https://tools.ietf.org/html/rfc5849#section-3.4.1
  ###

  signatureBaseString: (options, parameters) ->
    [
      (options.method).toUpperCase()
      @encodeOAuthData(@signatureBaseStringURI(options.url))
      @encodeOAuthData(parameters)
    ].join '&'

  ###*
  # Signature
  ###

  sign: (method, input, consumerSecret, tokenSecret) ->
    encoding = 'base64'
    result = ''

    key = @encodeOAuthData(consumerSecret) + '&' + @encodeOAuthData(tokenSecret)

    switch method
      when 'PLAINTEXT'
        result = key
      when 'RSA-SHA1'
        result = crypto.createSign(method).update(input).sign(key, encoding)
      when 'HMAC-SHA1'
        result = crypto.createHmac('sha1', key).update(input).digest(encoding)

    result

  ###*
  # Temporary Credentials
  # https://tools.ietf.org/html/rfc5849#section-2.1
  ###

  temporaryCredentials: (done) ->
    endpoint = @endpoints.credentials

    options =
      url: endpoint.url
      method: endpoint.method or 'post'
      qs:
        oauth_consumer_key: @client.oauth_consumer_key
        oauth_signature_method: @provider.oauth_signature_method or 'PLAINTEXT'
        oauth_timestamp: @timestamp()
        oauth_nonce: @nonce(32)
        oauth_callback: @provider.oauth_callback
        oauth_version: '1.0'
      headers:
        'User-Agent': agent
        'Accept': endpoint.accept or 'application/x-www-form-urlencoded'

    input = @signatureBaseString(options, @normalizeParameters(options.qs))

    options.qs.oauth_signature = @sign(signer, input, @client.oauth_consumer_secret)

    if realm
      options.qs.realm = @provider.realm

    options.qs.header[endpoint.header or 'Authorization'] = (endpoint.scheme or 'OAuth') + ' ' + @authorizationHeaderParams(params)

    promisedRequest options

  ###*
  # Resource Owner Authorization
  # https://tools.ietf.org/html/rfc5849#section-2.2
  ###

  resourceOwnerAuthorization: (token) ->
    endpoint = @endpoints.authorization

    param = endpoint.param or 'oauth_token'

    state: null, redirect_uri: endpoint.url + '?' + param + '=' + token

  ###*
  # Token Credentials
  # https://tools.ietf.org/html/rfc5849#section-2.3
  ###

  tokenCredentials: (authorization, secret, done) ->
    endpoint = @endpoints.token

    options =
      url: endpoint.url
      method: endpoint.method or 'post'
      qs:
        oauth_consumer_key: @client.oauth_consumer_key
        oauth_signature_method: @provider.oauth_signature_method or 'PLAINTEXT'
        oauth_timestamp: @timestamp()
        oauth_nonce: @nonce(32)
        oauth_token: authorization.oauth_token
        oauth_verifier: authorization.oauth_verifier or null
        oauth_version: '1.0'
      headers:
        'User-Agent': agent
        'Accept': endpoint.accept or 'application/x-www-form-urlencoded'

    input = @signatureBaseString(options, @normalizeParameters(options.qs))

    options.qs.oauth_signature = @sign(signer, input, @client.oauth_consumer_secret)
    options.qs.header[endpoint.header or 'Authorization'] = (endpoint.scheme or 'OAuth') + ' ' + @authorizationHeaderParams(params)

    promisedRequest options

  ###*
  # User Info
  ###

  userInfo: (credentials, done) ->
    endpoint = @endpoints.user

    options =
      url: endpoint.url
      method: endpoint.method or 'post'
      qs:
        oauth_consumer_key: @client.oauth_consumer_key
        oauth_signature_method: @provider.oauth_signature_method or 'PLAINTEXT'
        oauth_timestamp: @timestamp()
        oauth_nonce: @nonce(32)
        oauth_token: credentials.oauth_token
        oauth_version: '1.0'
        user_id: credentials.user_id
      headers:
        'User-Agent': agent
        'Accept': endpoint.accept or 'application/x-www-form-urlencoded'

    input = @signatureBaseString(options, @normalizeParameters(options.qs))

    options.qs.oauth_signature = @sign(signer, input, @client.oauth_consumer_secret)
    options.qs.header[endpoint.header or 'Authorization'] = (endpoint.scheme or 'OAuth') + ' ' + @authorizationHeaderParams(params)

    promisedRequest options

  setSessionDetails: (response, res) ->
    if !response and response.oauth_token
      return throw new Error('Failed to obtain OAuth request token')

    if !req.session['oauth']
      req.session['oauth'] = {}

    req.session['oauth'].oauth_token = response.oauth_token
    req.session['oauth'].oauth_token_secret = response.oauth_token_secret

  ###*
  # handle
  ###

  handle: (req, options) ->
    if req.query and req.query.oauth_token
      if !req.session['oauth']
        return throw new Error('Failed to find request token in session')

      secret = req.session['oauth'].oauth_token_secret

      Promise.bind this
        .then ->
          @tokenCredentials req.query, secret
        .then (credentials) ->
          delete req.session['oauth']
        .tap (credentials) ->
          @userInfo credentials
        .then (profile) ->
          @verify req, credentials, profile
    else
      Promise.bind this
        .then ->
          @temporaryCredentials()
        .tap (response) ->
          @setSessionDetails response, res
        .then (response) ->
          @resourceOwnerAuthorization response.oauth_token

        return

###*
# Exports
###

module.exports = OAuthStrategy
