module.exports = ->

  @factory 'AccessContext', (AccessPrincipal, injector, assert, debug) ->

    class AccessContext
      constructor: (context = {}) ->
        @model = AccessContext.ALL
        @methodName = AccessContext.ALL
        @permission = AccessContext.DEFAULT

        @principals = []

        for own key, value of context
          @[key] = value

        if not @accessType

          @accessType = switch @name
            when 'create', 'updateOrCreate', 'upsert'
              AccessContext.WRITE
            when 'exists', 'findById', 'find', 'findOne', 'count'
              AccessContext.READ
            when 'destroyById', 'deleteById', 'removeById'
              AccessContext.DELETE
            else
              AccessContext.ALL

        assert @accessType in AccessContext.accessTypes, 'invalid accessType ' + @accessType + '. It must be ' + AccessContext.accessTypes.join ', '

        if @modelName
          @model = injector.get @modelName

          @acls = @model.acls.filter (acl) =>
            wildcard = true

            if acl.methodName and acl.methodName isnt AccessContext.ALL
              wildcard = acl.methodName is @methodName

            acl.accessType in [ @accessType, 'ALL' ] and wildcard

      @ALL: 'ALL'
      @READ: 'READ'
      @REPLICATE: 'REPLICATE'
      @WRITE: 'WRITE'
      @DELETE: 'DELETE'
      @DEFAULT: 'DEFAULT'
      @ALLOW: 'ALLOW'
      @ALARM: 'ALARM'
      @AUDIT: 'AUDIT'
      @DENY: 'DENY'

      @accessTypes: [ "READ", "REPLICATE", "WRITE", "ALL", "DELETE" ]

      @permissionOrder:
        DEFAULT: 0
        ALLOW: 1
        ALARM: 2
        AUDIT: 3
        DENY: 4

      isWildcard: ->
        @model is AccessContext.ALL or
        @methodName is AccessContext.ALL or
        @accessType is AccessContext.ALL

      exactlyMatches: ({ model, methodName, accessType }) ->
        matchesModel = model is @modelName
        matchesMethodName = methodName is @methodName
        matchesAccessType = accessType is @accessType

        if matchesModel and matchesAccessType
          return matchesMethodName

        false

      isInRole: (acl) ->
        new Promise (resolve) =>
          role = 'isInRole(): ' + acl.principalId

          matchPrincipal = (acl) =>
            @principals.filter ({ type, id }) ->
              type is acl.principalType and id is acl.principalId

          ACL = injector.get 'ACL'

          resolver = ACL.resolvers[acl.principalId]

          if resolver
            resolver acl.principalId, @, (result) ->
              debug role + ', returns: ' + result
              return resolve result
            return

          if @principals.length is 0
            debug role + ', returns: false'
            return resolve false

          if matchPrincipal(acl).length
            debug role + ', returns: true'
            return resolve true

          resolve false

      getMatchingScore: (rule) ->
        if rule.score
          return rule.score

        props = [
          'model'
          'methodName'
          'accessType'
        ]

        score = 0
        i = 0

        while i < props.length
          # Shift the score by 4 for each of the properties as the weight
          if rule[props[i]]
            score = score * 4

            ruleValue = rule[props[i]]
            requestedValue = @[props[i]]

            if props[i] is 'accessType'
              ruleValue = ruleValue or AccessContext.ALL
              #requestedValue = requestedValue or AccessContext.ALL

            isMatchingMethodName = props[i] is 'methodName' and @methodName is ruleValue
            isMatchingAccessType = ruleValue is requestedValue

            if props[i] is 'accessType' and not isMatchingAccessType
              switch ruleValue
                when AccessContext.ALL, AccessContext.READ, AccessContext.WRITE, AccessContext.REPLICATE
                  # ALL should match READ, REPLICATE and WRITE
                  isMatchingAccessType = true
                when AccessContext.WRITE
                  # WRITE should match REPLICATE too
                  isMatchingAccessType = requestedValue is AccessContext.REPLICATE

            if isMatchingMethodName or isMatchingAccessType
              # Exact match
              score += 3
            else if ruleValue is AccessContext.ALL
              # Wildcard match
              score += 2
            else if requestedValue is AccessContext.ALL
              score += 1

          i++

        # Weigh against the principal type into 4 levels
        # - user level (explicitly allow/deny a given user)
        # - app level (explicitly allow/deny a given app)
        # - role level (role based authorization)
        # - other
        # user > app > role > ...
        if rule.principalType
          score = score * 4

          switch rule.principalType
            when AccessPrincipal.USER
              score += 4
            when AccessPrincipal.APP
              score += 3
            when AccessPrincipal.ROLE
              score += 2
            else
              score += 1

        # Weigh against the roles
        # everyone < authenticated/unauthenticated < related < owner < ...
        if rule.principalType is AccessPrincipal.ROLE
          score = score * 8

          ACL = injector.get 'ACL'

          switch rule.principalId
            when ACL.OWNER
              score += 4
            when ACL.RELATED
              score += 3
            when ACL.AUTHENTICATED, ACL.UNAUTHENTICATED
              score += 2
            when ACL.EVERYONE
              score += 1
            else
              score += 5

        score = score * 4
        score += AccessContext.permissionOrder[rule.permission or AccessContext.ALLOW] - 1

        rule.score = score

        score

      resolvePermission: (acls) ->
        acls = acls.sort (rule1, rule2) =>
          @getMatchingScore(rule2) - @getMatchingScore(rule1)

        score = 0
        i = 0

        while i < acls.length
          candidate = acls[i]

          if not candidate.score
            @getMatchingScore(candidate)

          score = candidate.score

          if score < 0
            # the highest scored ACL did not match
            break

          if not @isWildcard()
            # We should stop from the first match for non-wildcard
            @permission = candidate.permission
            break
          else
            if @exactlyMatches(candidate)
              @permission = candidate.permission
              break

            # For wildcard match, find the strongest permission
            candidateOrder = AccessContext.permissionOrder[candidate.permission]
            permissionOrder = AccessContext.permissionOrder[@permission]

            if candidateOrder > permissionOrder
              @permission = candidate.permission

          i++

        debug 'The following ACLs were searched: '

        acls.forEach (acl) ->
          debug '---ACL---'
          debug 'model %s', acl.modelName
          debug 'methodName %s', acl.methodName
          debug 'principalType %s', acl.principalType
          debug 'principalId %s', acl.principalId
          debug 'accessType %s', acl.accessType
          debug 'permission %s', acl.permission
          debug 'with score: %s', acl.score

          return

        if @permission is AccessContext.DEFAULT
          @permission = AccessContext.ALLOW

        @debugRequest()

        @isAllowed()

      isAllowed: ->
        @permission isnt AccessContext.DENY

      checkAccess: ->
        isInRole = @isInRole.bind @
        resolvePermission = @resolvePermission.bind @

        @debugContext()

        Promise.filter @acls, isInRole
          .then resolvePermission

      addPrincipal: (args...) ->
        principal = new AccessPrincipal args...

        exists = @principals.some (p) ->
          p.equals principal

        return false if exists

        @principals.push principal

        true

      get: (type) ->
        p = @principals.find (p) ->
          p.type is AccessPrincipal[type]
        p?.id or null

      getUserId: ->
        @get 'USER'

      getAppId: ->
        @get 'APP'

      toJSON: ->
        principals: @principals
        accessType: @accessType
        token: @token
        userId: @getUserId()
        appId: @getAppId()
        isAuthenticated: @isAuthenticated()

      toObject: ->
        @toJSON()

      setToken: (token) ->
        @token = token.id

        if token.userId
          @addPrincipal AccessPrincipal.USER, token.userId

        if token.appId
          @addPrincipal AccessPrincipal.APP, token.appId

        if token.roles and token.roles.length
          for role in token.roles
            @addPrincipal AccessPrincipal.ROLE, role

        if token.scopes and token.scopes.length
          for scope in token.scopes
            @addPrincipal AccessPrincipal.SCOPE, scope

      isAuthenticated: ->
        not not (@getUserId() or @getAppId())

      debugContext: ->
        debug '---AccessContext---'

        if @principals.length
          debug 'principals:'
          @principals.forEach (principal) ->
            debug ' principal: %j', principal
        else
          debug 'principals: %j', @principals

        debug 'modelName %s', @modelName
        debug 'modelId %s', @modelId
        debug 'methodName %s', @methodName
        debug 'accessType %s', @accessType

        if @token
          debug 'accessToken:', @token

        debug 'getUserId() %s', @getUserId()
        debug 'isAuthenticated() %s', @isAuthenticated()

        return

      debugRequest: ->
        debug '---AccessRequest---'

        debug ' permission %s', @permission
        debug ' isWildcard() %s', @isWildcard()
        debug ' isAllowed() %s', @isAllowed()

        return
