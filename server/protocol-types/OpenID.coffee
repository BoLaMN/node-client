###*
# Module dependencies.
###

openid = require 'openid'
url = require '../utils/url'

{ SimpleRegistration
  AttributeExchange
  UserInterface
  PAPE
  OAuthHybrid
  RelyingParty } = openid

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
      'request'
    else
      'callback'
      
  callback: (req) ->
    if req.query['openid.mode'] is 'cancel'
      return throw new Error 'OpenID authentication canceled'

    new Promise (resolve, reject) ->
      @_relyingParty.verifyAssertion req.url, (err, result) ->
        if  err 
          return reject err 

        if not result.authenticated
          return reject new Error 'OpenID authentication failed'

        resolve result

  request: (req) ->
    identifier = req.body[@_identifierField] or req.query[@_identifierField] or @_providerURL

    if not identifier
      return throw new Error 'Missing OpenID identifier'

    new Promise (resolve, reject) ->
      @_relyingParty.authenticate identifier, false, (err, providerUrl) ->
        if err 
          return reject err 

          if not providerUrl
            return reject new Error 'Failed to discover OP endpoint URL', err

          resolve url.join req.issuer, providerUrl

###*
# Exports
###

module.exports = OpenIDStrategy
