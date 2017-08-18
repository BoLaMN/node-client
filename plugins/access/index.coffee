module.exports = (app) ->

  app.module 'Access', [ ]

  .initializer ->

    @include './errors'
    @include './access-context'
    @include './principal'

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

      ACL

    @factory 'AccessHandler', (OAuthError, ServerError, AccessDeniedError, InvalidArgumentError, AccessContext, debug) ->

      class AccessHandler
        constructor: (@request, @response) ->
          { params, query, body, route } = @request
          { method, name, modelName } = route

          modelId = params.id or body.id or query.id

          @context = new AccessContext
            modelName: modelName
            modelId: modelId
            methodName: name
            accessType: @getAccessType route

          @authenticateHandler = handle: ->
            Promise.resolve id: 1, userId: '1', roles: []

        @check: (req, res) ->
          handler = new AccessHandler req, res

          handler.getAuth()

        getAccessType: (route) ->
          if route.accessType
            return route.accessType

          if route.method in [ 'get', 'head' ]
            return AccessContext.READ

        getAuth: ->

          if not @context.modelName
            return Promise.resolve()

          @context.checkAccess()
            .then (@allowed) =>
              if @allowed
                return Promise.resolve @allowed

              @authenticateHandler.handle @request, @response
                .then (token) ->
                  if not token.userId and not token.roles
                    return Promise.reject new ServerError 'USEROBJECT'

                  token
            .then @afterAuth.bind @

        afterAuth: (token) ->
          if @allowed
            return Promise.resolve @allowed

          if not token
            return Promise.reject new AccessDeniedError 'NOACCESS'

          @context.setToken token

          @context.checkAccess()
            .then (allowed) ->
              if not allowed
                return Promise.reject new AccessDeniedError 'NOACCESS'
