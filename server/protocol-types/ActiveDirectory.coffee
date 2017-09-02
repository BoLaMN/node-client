'use strict'

LdapActiveDirectoryStrategy = require './LdapActiveDirectory'

class ActiveDirectoryStrategy extends LdapActiveDirectoryStrategy
  constructor: (options) ->
    super options

    @name = 'ActiveDirectory'

module.exports = ActiveDirectoryStrategy
