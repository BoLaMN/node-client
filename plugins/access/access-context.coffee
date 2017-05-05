debug = require('debug')('security:acl')

module.exports = ->

  @factory 'AccessContext', (AccessPrincipal, injector) ->

    class AccessContext
      constructor: (context = {}) ->
        @principals = context.principals or []

        model = context.model
        model = if typeof model is 'string' then injector.get(model) else model

        @aclModel = injector.get 'ACL'
        @tokenModel = injector.get 'AccessToken'

        @model = model and model.modelName
        @modelName = model and model.modelName
        @modelId = context.id or context.modelId
        @modelCtor = model

        @property = context.property or AccessContext.ALL

        @method = context.methodName
        @methodNames = []

        @sharedMethod = context.method
        @sharedClass = @sharedMethod and @sharedMethod.sharedClass

        if @sharedMethod
          @methodNames = @sharedMethod.aliases.concat([ @sharedMethod.name ])

        @accessType = context.accessType or @ALL
        @accessToken = context.accessToken or new @tokenModel accessToken: '$anonymous'

        @remotingContext = context.context

        return

      @ALL: 'ALL'
      @READ: 'READ'
      @REPLICATE: 'REPLICATE'
      @WRITE: 'WRITE'
      @DELETE: 'DELETE'
      @EXECUTE: 'EXECUTE'
      @DEFAULT: 'DEFAULT'
      @ALLOW: 'ALLOW'
      @ALARM: 'ALARM'
      @AUDIT: 'AUDIT'
      @DENY: 'DENY'

      @permissionOrder:
        DEFAULT: 0
        ALLOW: 1
        ALARM: 2
        AUDIT: 3
        DENY: 4

      generateNewACL: (property, acl) ->
        if property is '*'
          property = AccessContext.ALL

        if acl.accessType is '*'
          acl.accessType = AccessContext.ALL

        if acl.principalType is '*'
          acl.principalType = AccessContext.ALL

        if acl.principalId is '*'
          acl.principalId = AccessContext.ALL

        new @aclModel
          model: @modelName
          property: property or null
          principalType: acl.principalType
          principalId: acl.principalId
          accessType: acl.accessType or AccessContext.ALL
          permission: acl.permission

      getAcls: ->
        if @acls
          return Promise.resolve @acls

        #Promise.bind this
        #  .then ->
        #    @getQuery()
        #  .then (query) ->
        #    @getDynamicAcls query
        #  .then (dynamicAcls) ->
        @getStaticAcls []

      getDynamicAcls: (query) ->
        @aclModel.find query

      getStaticAcls: (dynamicAcls) ->
        { settings } = injector.get @modelName

        if not settings.acls
          return Promise.resolve @acls

        staticACLs = settings.acls.map (acl) =>
          prop = acl.property

          if Array.isArray(prop) and prop.indexOf(@property) >= 0
            prop = @property

          if !prop or prop == (AccessContext.ALL or '*') or @property == prop
            return @generateNewACL prop, acl

          false

        @acls = dynamicAcls.concat staticACLs
          .filter (a) -> a

        Promise.resolve @acls

      getQuery: ->
        query = where:
          model: @modelName
          property: @getPropertyTypeQuery()
          accessType: @getAccessTypeQuery()

        Promise.resolve query

      getPropertyTypeQuery: ->
        switch @property
          when AccessContext.ALL
            undefined
          else
            inq: @methodNames.concat [ AccessContext.ALL ]

      getAccessTypeQuery: ->
        switch @accessType
          when AccessContext.ALL
            undefined
          when AccessContext.REPLICATE
            inq: [
              AccessContext.REPLICATE
              AccessContext.WRITE
              AccessContext.ALL
            ]
          else
            inq: [
              @accessType
              AccessContext.ALL
            ]

      addPrincipal: (principalType, principalId, principalName) ->
        principal = new AccessPrincipal(principalType, principalId, principalName)
        i = 0
        while i < @principals.length
          p = @principals[i]
          if p.equals(principal)
            return false
          i++
        @principals.push principal
        true

      getUserId: ->
        i = 0
        while i < @principals.length
          p = @principals[i]
          if p.type == AccessPrincipal.USER
            return p.id
          i++
        null

      getAppId: ->
        i = 0
        while i < @principals.length
          p = @principals[i]
          if p.type == AccessPrincipal.APP
            return p.id
          i++
        null

      toJSON: ->
        principals: @principals
        accessType: @accessType
        accessToken: @accessToken
        userId: @getUserId()
        appId: @getAppId()
        isAuthenticated: @isAuthenticated()

      toObject: ->
        principals: @principals
        accessType: @accessType
        accessToken: @accessToken
        userId: @getUserId()
        appId: @getAppId()
        isAuthenticated: @isAuthenticated()

      isAuthenticated: ->
        ! !(@getUserId() or @getAppId())

      debug: ->
        if debug.enabled
          debug '---AccessContext---'

          if @principals.length
            debug 'principals:'
            @principals.forEach (principal) ->
              debug ' principal: %j', principal
          else
            debug 'principals: %j', @principals

          debug 'modelName %s', @modelName
          debug 'modelId %s', @modelId
          debug 'property %s', @property
          debug 'method %s', @method
          debug 'accessType %s', @accessType

          if @accessToken
            debug 'accessToken: %s', @accessToken

          debug 'getUserId() %s', @getUserId()
          debug 'isAuthenticated() %s', @isAuthenticated()

        return
