module.exports = ->

  @factory 'ModelACL', (ACL) ->

    class ModelACL

      @acl: (config) ->

        if config.accessType is '*'
          config.accessType = AccessContext.ALL

        if config.principalType is '*'
          config.principalType = AccessContext.ALL

        if config.principalId is '*'
          config.principalId = AccessContext.ALL

        config.methodName ?= null
        config.accessType ?= AccessContext.ALL

        acl = new ACL config

        @acls.push acl

        @
