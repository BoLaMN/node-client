'use strict'

assert = require 'assert'

{ promisifyAll, bind } = require 'bluebird'
{ defaults } = require 'lodash'

serverTypes =
  LDAP: require 'ldapauth-fork'
  ActiveDirectory: require 'adauth'

class LdapActiveDirectoryStrategy
  constructor: (options) ->
    assert typeof options is 'object', 'LDAP authentication strategy requires options'

    defaults @options, options, LdapActiveDirectoryStrategy.defaults

    module = serverTypes[@name]

    @auth = promisifyAll new module @options.server

  @defaults:
    usernameField: 'username'
    passwordField: 'password'

  verify: (request, info) ->
    User = request.app.models.User

    if not info
      return throw new Error 'Invalid username/password'

    Promise.bind this
      .then ->
        User.lookup info
      .then (user) ->
        User.connect user, @provider, auth, info

  handleError: (err) ->
    if err.name is 'InvalidCredentialsError' or err.name is 'NoSuchObjectError' or typeof err is 'string' and err.match(/no such user/i)
      throw new Error 'Invalid username/password'

    if err.name is 'ConstraintViolationError'
      throw new Error 'Exceeded password retry limit, account locked'

    throw new Error err

  getCredentials: ({ body, query }) ->
    { usernameField, passwordField } = @options

    username: body[usernameField] or query[usernameField]
    password: body[passwordField] or query[passwordField]

  ###*
  # handle the request coming from a form or such.
  ###

  handle: (request) ->
    { username, password } = @getCredentials request

    if not username or not password
      throw new Error 'Missing credentials'

    bind this
      .then ->
        @auth.handleAsync username, password
      .tap ->
        @auth.closeAsync()
      .then (info) ->
        @verify request, info
      .catch (error) ->
        @handleError error

module.exports = LdapActiveDirectoryStrategy
