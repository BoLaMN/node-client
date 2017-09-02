'use strict'

LdapActiveDirectoryStrategy = require './LdapActiveDirectory'

class LDAPStrategy extends LdapActiveDirectoryStrategy
  constructor: (options) ->
    super options

    @name = 'LDAP'

module.exports = LDAPStrategy
