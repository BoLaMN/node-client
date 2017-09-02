###*
# Module dependencies
###

{ SAML } = require 'passport-saml'

fs = require 'fs'
Promise = require 'bluebird'

{ promisfy, promisfyAll } = Promise

###*
# Exports
###

class SAMLStrategy
  constructor: (@provider, @configuration) ->
    @saml = promisfyAll new SAML @provider

    for own key,value of @provider
      @[key] = value

    if typeof @configuration.cert == 'string'
      try
        @configuration.cert = fs.readFileSync(@configuration.cert, 'utf-8')
      catch err

    @passReqToCallback = true
    @name = 'saml'

    return

  validateCallback: (req, profile, loggedOut) ->
    if loggedOut
      req.logout()

      if profile
        req.samlLogoutRequest = profile
        @saml.getLogoutResponseUrlAsync(req).then @redirectIfSuccess
        return

      return Promise.resolve()

    @verify req, profile
      .then (user) ->
        if not user
          return throw new Error profile

        user

  redirectIfSuccess: (url) ->
    state: null, redirect_uri: url

  handle: (req, options) ->
    options.samlFallback = options.samlFallback or 'login-request'

    if req.body and (req.body.SAMLResponse or req.body.SAMLRequest)
      return @saml.validatePostResponseAsync(req.body)
        .spread (profile, loggedOut) ->
          @validateCallback req, profile, loggedOut

    if options.samlFallback is 'login-request'
      if @_authnRequestBinding == 'HTTP-POST'
        return @saml.getAuthorizeFormAsync req
      else
        return @saml.getAuthorizeUrlAsync(req).then @redirectIfSuccess

    if options.samlFallback is 'logout-request'
      return @saml.getLogoutUrlAsync(req).then @redirectIfSuccess

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

module.exports = SAMLStrategy
