debug = require('debug')('security:acl')

module.exports = ->

  @factory 'AccessContext', (AccessPrincipal, injector, AccessRequest, ACL) ->

    class AccessContext
      constructor: (context = {}) ->
        @accessType = @ALL

        @methodNames = []
        @principals = []

        for own key, value of context
          @[key] = value

        @model = injector.get @modelName
        @acls = @model.acls

        if @method
          @class = @method.sharedClass
          @methodNames = @method.aliases.concat [ @method.name ]

        AccessToken = injector.get 'AccessToken'

        @token ?= new AccessToken accessToken: '$anonymous'

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

      isInRole: (acl, callback) ->
        debug 'isInRole(): %s', acl.principalId

        @debug()

        matchPrincipal = (acl) =>
          @principals.filter ({ type, id }) ->
            type is acl.principalType and id is acl.principalId

        resolver = ACL.resolvers[acl.principalId]

        if resolver
          debug 'Custom resolver found for role %s', acl.principalId
          resolver acl.principalId, @, (result) ->
            debug 'isInRole() returns: ' + result
            return callback result
          return

        if @principals.length is 0
          debug 'isInRole() returns: false'
          return callback false

        if matchPrincipal(acl).length
          debug 'isInRole() returns: true'
          return callback true

        callback false

      getMatchingScore: (rule, req) ->
        props = [
          'model'
          'property'
          'accessType'
        ]

        score = 0
        i = 0

        while i < props.length
          # Shift the score by 4 for each of the properties as the weight
          if rule[props[i]]
            score = score * 4

            ruleValue = rule[props[i]]
            requestedValue = req[props[i]]

            if props[i] is 'accessType'
              ruleValue = ruleValue or AccessContext.ALL
              #requestedValue = requestedValue or AccessContext.ALL

            isMatchingMethodName = props[i] == 'property' and req.methodNames.indexOf(ruleValue) != -1
            isMatchingAccessType = ruleValue == requestedValue

            if props[i] == 'accessType' and !isMatchingAccessType
              switch ruleValue
                when AccessContext.EXECUTE, AccessContext.READ, AccessContext.WRITE, AccessContext.REPLICATE
                  # EXECUTE should match READ, REPLICATE and WRITE
                  isMatchingAccessType = true
                when AccessContext.WRITE
                  # WRITE should match REPLICATE too
                  isMatchingAccessType = requestedValue == AccessContext.REPLICATE

            if isMatchingMethodName or isMatchingAccessType
              # Exact match
              score += 3
            else if ruleValue == AccessContext.ALL
              # Wildcard match
              score += 2
            else if requestedValue == AccessContext.ALL
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
        if rule.principalType == AccessPrincipal.ROLE
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

        score

      resolvePermission: (acls) ->
        req = new AccessRequest @

        acls = acls.sort (rule1, rule2) =>
          @getMatchingScore(rule2, req) - @getMatchingScore(rule1, req)

        permission = AccessContext.DEFAULT

        score = 0
        i = 0

        while i < acls.length
          candidate = acls[i]

          if not acls[i].score
            acls[i].score = @getMatchingScore(candidate, req)

          score = acls[i].score

          if score < 0
            # the highest scored ACL did not match
            break

          if !req.isWildcard()
            # We should stop from the first match for non-wildcard
            permission = candidate.permission
            break
          else
            if req.exactlyMatches(candidate)
              permission = candidate.permission
              break

            # For wildcard match, find the strongest permission
            candidateOrder = AccessContext.permissionOrder[candidate.permission]
            permissionOrder = AccessContext.permissionOrder[permission]

            if candidateOrder > permissionOrder
              permission = candidate.permission

          i++

        if debug.enabled
          debug 'The following ACLs were searched: '

          acls.forEach (acl) ->
            acl.debug()

        req.permission = permission

        req

      setAccessTypeForRoute: (route) ->

        getAccessType = ->
          if route.accessType
            assert route.accessType in [ "READ", "REPLICATE", "WRITE", "EXECUTE", "DELETE" ], 'invalid accessType ' + method.accessType + '. It must be "READ", "REPLICATE", "WRITE", or "EXECUTE"'
            return route.accessType

          verb = route.method

          if typeof verb is 'string'
            verb = verb.toUpperCase()

          if verb in [ 'GET', 'HEAD' ]
            return AccessContext.READ

          switch method.name
            when 'create', 'updateOrCreate', 'upsert'
              return AccessContext.WRITE
            when 'exists', 'findById', 'find', 'findOne', 'count'
              return AccessContext.READ
            when 'destroyById', 'deleteById', 'removeById'
              return AccessContext.DELETE
            else
              return AccessContext.EXECUTE

        @accessType = getAccessType()

        return

      checkAccess: ->

        new Promise (resolve, reject) =>
          async.filter @acls, (acl, cb) =>
            @isInRole acl, cb
          , (acls) =>
            resolved = @resolvePermission acls

            if resolved and resolved.permission == AccessContext.DEFAULT
              resolved.permission = AccessContext.ALLOW

            resolved.debug()

            resolve resolved.isAllowed()

          return

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
        p.id or null

      getUserId: ->
        @get 'USER'

      getAppId: ->
        @get 'APP'

      toJSON: ->
        principals: @principals
        accessType: @accessType
        accessToken: @accessToken
        userId: @getUserId()
        appId: @getAppId()
        isAuthenticated: @isAuthenticated()

      toObject: ->
        @toJSON()

      setToken: (token) ->
        @token = token.accessToken

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
          debug 'method %s', @methodName
          debug 'accessType %s', @accessType

          if @token
            debug 'accessToken: %s', @token

          debug 'getUserId() %s', @getUserId()
          debug 'isAuthenticated() %s', @isAuthenticated()

        return
