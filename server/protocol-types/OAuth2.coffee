###*
# Module dependencies
###

url = require '../utils/url'
promisedRequest = require "request-promise"

agent = 'Identity Manager/0.1'

###*
# OAuth2Strategy
#
# Provider is an object defining the details of the authentication API.
# Client is an object containing provider registration info and options.
# Verify is the Passport callback to invoke after authenticating
###

class OAuth2Strategy
  constructor: (@provider, @client, @issuer) ->
    for own key,value of @provider
      @[key] = value

    return

  ###*
  # Base64 Credentials
  #
  # Base64 encodes the user:password value for an HTTP Basic Authorization
  # header from a provider configuration object. The provider object should
  # specify a client_id and client_secret.
  ###

  base64credentials: ->
    { client_id, client_secret } = @client

    credentials = client_id + ':' + client_secret

    new Buffer(credentials).toString 'base64'

  ###*
  # handle
  ###

  handle: (request) ->
    { code, error } = request.query

    if error
      throw new ServerError error

    if code
      'callback'
    else
      'request'

  ###*
  # Authorization Request
  ###

  request: (request, response) ->
    options = url.parse @endpoints.authorize.url

    { clientId, grantType,
      providerId, responseType } = request.params

    redirectUri = [ clientId, grantType, providerId, responseType ].join '/'

    options.query =
      response_type: 'code'
      client_id: @client.client_id
      redirect_uri: url.join @issuer, '/users/callback/' + redirectUri

    if @provider.scope or @client.scope
      s1 = @provider.scope or []
      s2 = @client.scope or []
      sp = @provider.separator or ' '
      options.query.scope = s1.concat(s2).join(sp)

    response.redirect url.format options

    null

  ###*
  # Authorization Code Grant Request
  ###

  callback: (request, response) ->
    endpoint = @endpoints.token

    { clientId, grantType,
      providerId, responseType } = request.params

    redirectUri = [ clientId, grantType, providerId, responseType ].join '/'

    options =
      url: endpoint.url
      method: endpoint.method or 'post'
      json: true
      form:
        grant_type: 'authorization_code'
        code: code
        redirect_uri: url.join @issuer, '/users/callback/' + redirectUri
      headers:
        'User-Agent': agent
        'Accept': endpoint.accept or 'application/json'

    if endpoint.auth is 'client_secret_basic'
      options.headers.Authorization = 'Basic ' + @base64credentials()

    if endpoint.auth is 'client_secret_post'
      options.form.client_id = @client.client_id
      options.form.client_secret = @client.client_secret

    promisedRequest options
      .then @userInfo

  ###*
  # User Info
  ###

  userInfo: (auth) ->
    endpoint = @endpoints.user

    options =
      url: endpoint.url
      method: endpoint.method or 'post'
      qs: endpoint.params or {}
      json: true
      headers:
        'User-Agent': agent
        'Accept': endpoint.accept or 'application/json'

    if endpoint.auth
      { header
        scheme
        query } = endpoint.auth

      if header
        if scheme is 'Basic'
          options.headers[header] = @base64credentials()
        else
          options.headers[header] = [
            scheme
            auth.access_token
          ].join ' '

      if query
        options.qs[query] = auth.access_token

    promisedRequest options

module.exports = OAuth2Strategy
