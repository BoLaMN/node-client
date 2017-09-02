###*
# OpenIDStrategy
#
# Provider is an object defining the details of the authentication API.
# Client is an object containing provider registration info and @provider.
# Verify is the Passport callback to invoke after authenticating
###

###*
# Module dependencies.
###

openid = require 'openid'
Promise = require 'bluebird'
url = require '../utils/url'

{ promisifyAll, bind } = Promise

{ SimpleRegistration
  AttributeExchange
  UserInterface
  PAPE
  OAuthHybrid
  RelyingParty } = openid

{ ServerError } = require '../errors/server-error'

class OpenIDStrategy
  constructor: (@provider) ->
    if !@provider.returnURL
      throw new Error 'OpenID authentication requires a returnURL option'

    @profile = true
    @passReqToCallback = true

    for own key,value of @provider
      @[key] = value

    @name = @provider.id

    if not @provider.returnURL
      @provider.returnURL = @provider.callbackURL

    @name = 'openid'

    extensions = []

    if @provider.profile
      sreg = new SimpleRegistration(
        'fullname': true
        'nickname': true
        'email': true
        'dob': true
        'gender': true
        'postcode': true
        'country': true
        'timezone': true
        'language': true)

      extensions.push sreg

    if @provider.profile
      ax = new AttributeExchange(
        'http://axschema.org/namePerson': 'required'
        'http://axschema.org/namePerson/first': 'required'
        'http://axschema.org/namePerson/last': 'required'
        'http://axschema.org/contact/email': 'required')

      extensions.push ax

    if @provider.ui
      # ui: { mode: 'popup', icon: true, lang: 'fr-FR' }
      ui = new UserInterface(options.ui)
      extensions.push ui

    if @provider.pape
      papeOptions = {}

      if @provider.pape.hasOwnProperty('maxAuthAge')
        papeOptions.max_auth_age = @provider.pape.maxAuthAge

      if @provider.pape.preferredAuthPolicies
        if typeof @provider.pape.preferredAuthPolicies == 'string'
          papeOptions.preferred_auth_policies = @provider.pape.preferredAuthPolicies
        else if Array.isArray(options.pape.preferredAuthPolicies)
          papeOptions.preferred_auth_policies = @provider.pape.preferredAuthPolicies.join(' ')

      pape = new PAPE(papeOptions)
      extensions.push pape

    if @provider.oauth
      oauthOptions =
        consumerKey: @provider.oauth.consumerKey
        scope: @provider.oauth.scope

      oauth = new OAuthHybrid(oauthOptions)
      extensions.push oauth

    stateless = @provider.stateless or false
    secure = @provider.secure or true

    @_relyingParty = promisifyAll new RelyingParty(options.returnURL, @provider.realm, stateless, secure, extensions)
    @_providerURL = @provider.providerURL
    @_identifierField = @provider.identifierField or 'openid_identifier'

    return

  handle: (req) ->
    if req.query['openid.mode']
      if req.query['openid.mode'] is 'cancel'
        return throw new Error 'OpenID authentication canceled'

      Promise.bind this
        .then ->
          @_relyingParty.verifyAssertionAsync req.url
        .then (result) ->
          @verify req, result

    else
      identifier = req.body[@_identifierField] or req.query[@_identifierField] or @_providerURL

      if not identifier
        return throw new ServerError('Missing OpenID identifier')

      @_relyingParty.authenticateAsync identifier, false
        .then (providerUrl) ->
          if !providerUrl
            return throw new ServerError('Failed to discover OP endpoint URL', err)

          state: null, redirect_uri: url.join req.issuer, providerUrl

  saveAssociation: (fn) ->

    openid.saveAssociation = (provider, type, handle, secret, expiry, callback) ->
      fn handle, provider, type, secret, expiry, callback
      return

    this

  loadAssociation: (fn) ->

    openid.loadAssociation = (handle, callback) ->
      fn handle, (err, provider, algorithm, secret) ->
        if err
          return callback(err, null)

        obj =
          provider: provider
          type: algorithm
          secret: secret

        callback null, obj

      return

    this

  saveDiscoveredInformation: (fn) ->
    openid.saveDiscoveredInformation = fn
    this

  loadDiscoveredInformation: (fn) ->
    openid.loadDiscoveredInformation = fn
    this

  _parseProfileExt: (params) ->
    profile = {}

    profile.displayName = params['fullname']
    profile.emails = [ { value: params['email'] } ]

    profile.name =
      familyName: params['lastname']
      givenName: params['firstname']

    if !profile.displayName
      if params['firstname'] and params['lastname']
        profile.displayName = params['firstname'] + ' ' + params['lastname']

    if !profile.emails
      profile.emails = [ { value: params['email'] } ]

    profile

  _parsePAPEExt: (params) ->
    pape = {}

    if params['auth_policies']
      pape.authPolicies = params['auth_policies'].split(' ')

    if params['auth_time']
      pape.authTime = new Date(params['auth_time'])

    pape

  _parseOAuthExt: (params) ->
    oauth = {}

    if params['request_token']
      oauth.requestToken = params['request_token']

    oauth

  ###*
  # Verifier
  ###

  verify: (req, result) ->
    if !result.authenticated
      return throw new Error('OpenID authentication failed')

    profile = @_parseProfileExt(result)
    pape = @_parsePAPEExt(result)
    oauth = @_parseOAuthExt(result)

    auth =
      id: req.query['openid.identity']
      req_query: req.query

    userInfo.id = req.query['openid.identity']
    userInfo.name = req.query['openid.ext2.value.fullname']
    userInfo.givenName = req.query['openid.ext2.value.firstname']
    userInfo.familyName = req.query['openid.ext2.value.lastname']
    userInfo.email = req.query['openid.ext2.value.email']

    { User } = req.app.models

    User.connect req, auth, userInfo

###*
# Exports
###

module.exports = OpenIDStrategy
