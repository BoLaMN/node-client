
module.exports = (app) ->

  app.module 'Access', [ 'Data' ]

  .initializer ->

    @include './errors'
    @include './access-context'
    @include './access-request'
    @include './is-in-role'
    @include './principal'
    @include './resolve-permission'
    @include './score'
    @include './utils/request'
    @include './utils/response'

    @decorator 'ACL', (ACL) ->
      ACL.resolvers = {}

      ###*
      # Add custom handler for roles.
      # @param {String} role Name of role.
      # @param {Function} resolver Function that determines if a principal is in the specified role.
      # Signature must be `function(role, context, callback)`
      ###

      ACL.registerResolver = (role, resolver) ->
        ACL.resolvers[role] = resolver
        return

      ###*
      # Check if the given principal is allowed to access the model/property
      # @param {String} principalType The principal type.
      # @param {String} principalId The principal ID.
      # @param {String} model The model name.
      # @param {String} property The property/method/relation name.
      # @param {String} accessType The access type.
      # @callback {Function} callback Callback function.
      # @param {String|Error} err The error object
      # @param {AccessRequest} result The access permission
      ###

      ACL::debug = ->
        if debug.enabled
          debug '---ACL---'
          debug 'model %s', @model
          debug 'property %s', @property
          debug 'principalType %s', @principalType
          debug 'principalId %s', @principalId
          debug 'accessType %s', @accessType
          debug 'permission %s', @permission
          debug 'with score: %s', @score

        return

      ACL

    @factory 'AccessHandler', (OAuthError, ServerError, AccessDeniedError, InvalidArgumentError, AccessContext, AccessPrincipal, AccessReq, AccessRes, resolvePermission, isInRole) ->

      getAccessTypeForRoute = (route) ->
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

        return

      class AccessHandler
        constructor: (options) ->
          for key, value of options
            @[key] = value

          @authenticateHandler = new AuthenticateHandler
            tokenModel: @tokenModel
            addAcceptedScopesHeader: true
            addAuthorizedScopesHeader: true
            allowBearerTokensInQueryString: false

        handle: (request, response) ->
          if not request instanceof Request
            throw new InvalidArgumentError 'REQUEST'

          if not response instanceof Response
            throw new InvalidArgumentError 'RESPONSE'

          acls = null
          allowed = null

          Promise.bind this
            .then ->
              @accessContext.getAcls()
            .then (effectiveAcls) ->
              acls = effectiveAcls
              @checkAccessForContext acls, @accessContext
            .then (@allowed) ->
              @getAuth request, response
            .then (token) ->
              @afterAuth request, acls, token
            .catch (e) ->
              if not e instanceof OAuthError
                e = new ServerError e

              throw e

              return

        ###*
        # Check if the request has the permission to access.
        # @options {Object} context See below.
        # @property {Object[]} principals An array of principals.
        # @property {String|Model} model The model name or model class.
        # @property {*} id The model instance ID.
        # @property {String} property The property/method/relation name.
        # @property {String} accessType The access type:
        #   READ, REPLICATE, WRITE, or EXECUTE.
        # @param {Function} callback Callback function
        ###

        checkAccessForContext: (acls, context) ->
          ACL = @aclModel

          new Promise (resolve, reject) ->
            async.filter acls, (acl, cb) ->
              isInRole acl, context, cb
            , (effectiveAcls) ->
              resolved = resolvePermission effectiveAcls, context

              if resolved and resolved.permission == AccessContext.DEFAULT
                resolved.permission = AccessContext.ALLOW

              resolved.debug()

              resolve resolved.isAllowed()

            return

        getAuth: (request, response) ->
          if @allowed
            return Promise.resolve @allowed

          @authenticateHandler.handle request, response
            .then (token) ->
              if not token.userId and not token.roles
                throw new ServerError 'USEROBJECT'

              token

        afterAuth: (request, acls, token) ->
          if @allowed
            return Promise.resolve @allowed

          if not token
            throw new AccessDeniedError 'NOACCESS'

          @accessContext.accessToken = token.accessToken

          if token.userId
            @accessContext.addPrincipal AccessPrincipal.USER, token.userId

          if token.appId
            @accessContext.addPrincipal AccessPrincipal.APP, token.appId

          if token.roles and token.roles.length
            for role in token.roles
              @accessContext.addPrincipal AccessPrincipal.ROLE, role

          if token.scopes and token.scopes.length
            for scope in token.scopes
              @accessContext.addPrincipal AccessPrincipal.SCOPE, scope

          request.accessContext = @accessContext

          @checkAccessForContext(acls, @accessContext)
            .then (allowed) ->
              if not allowed
                throw new AccessDeniedError 'NOACCESS'

              allowed

      (req, res, next) ->

        request = new AccessReq req
        response = new AccessRes res

        { params, query, body, route } = req
        { method, name, parent } = route

        modelId = params.id or body.id or query.id

        accessContext = new AccessContext
          model: parent.name
          modelId: modelId
          property: method.name
          method: method
          methodName: name
          accessType: getAccessTypeForRoute route
          context:
            req: req
            res: res

        new AccessHandler accessContext
          .handle request, response
          .tap ->
            req.accessContext = request.accessContext
          .asCallback next
