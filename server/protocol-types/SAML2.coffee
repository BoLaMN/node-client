###*
# Module dependencies
###

{ SAML } = require 'passport-saml'

fs = require 'fs'

###*
# Exports
###

class SAMLStrategy
  constructor: (@provider, @configuration) ->
    @saml = promisfyAll new SAML @provider

    for own key,value of @provider
      @[key] = value

    if typeof @configuration.cert is 'string'
      try
        @configuration.cert = fs.readFileSync(@configuration.cert, 'utf-8')
      catch err

    @passReqToCallback = true
    @name = 'saml'

  handle: (req) ->
    if req.body?.SAMLResponse or req.body?.SAMLRequest
      'callback'
    else 
      'request'

  request: (req, options) ->
    samlFallback = options.samlFallback or 'login-request'
 
    new Promise (resolve, reject) =>

      finish = (err, res) ->
        if err 
          return reject err 

        resolve res 

      switch samlFallback 
        when 'login-request'
          if @_authnRequestBinding == 'HTTP-POST'
            return @saml.getAuthorizeForm req, finish
          else
            return @saml.getAuthorizeUrl req, finish
        when 'logout-request'
          return @saml.getLogoutUrl req, finish

  callback: (req) ->  
    
    new Promise (resolve, reject) =>

      finish = (err, profile, loggedOut) ->
        if err 
          return reject err 

        if loggedOut
          req.logout()

        resolve profile

      @saml.validatePostResponse req.body, finish

module.exports = SAMLStrategy
