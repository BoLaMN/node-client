module.exports = ->

  @factory 'ModelACL', (Models, AccessContext) ->

    class ModelACL

      @acl: (config) ->

        if config.accessType is '*'
          config.accessType = AccessContext.ALL

        if config.principalType is '*'
          config.principalType = AccessContext.ALL

        if config.principalId is '*'
          config.principalId = AccessContext.ALL

        config.accessType ?= AccessContext.ALL
        config.methodName ?= AccessContext.ALL

        config.modelName = @name

        Models.get 'ACL', (ACL) =>
          @acls.push new ACL config

        @
