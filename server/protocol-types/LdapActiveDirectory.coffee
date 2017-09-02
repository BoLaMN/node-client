'use strict'

assert = require 'assert'

serverTypes =
  LDAP: require 'ldapauth-fork'
  ActiveDirectory: require 'adauth'

class LdapActiveDirectoryStrategy
  constructor: (options = {}) ->
    for own key, val of options 
      @[key] = val 

    @auth = new serverTypes[@name] @options.server

  ###*
  # handle the request coming from a form or such.
  ###

  handle: (req) ->
    'request'
    
  request: (username, password) ->
    if not username or not password
      return throw new Error 'Missing credentials'

    new Promise (resolve, reject) =>
      @auth.handle username, password, (err, info) ->
        if err 
          return reject err 

        @auth.close()

        resolve info

        return 
      return 

module.exports = LdapActiveDirectoryStrategy
