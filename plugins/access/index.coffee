
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
      # Check if the given principal is allowed to access the model/methodName
      # @param {String} principalType The principal type.
      # @param {String} principalId The principal ID.
      # @param {String} model The model name.
      # @param {String} methodName The methodName/method/relation name.
      # @param {String} accessType The access type.
      # @callback {Function} callback Callback function.
      # @param {String|Error} err The error object
      # @param {AccessRequest} result The access permission
      ###

      ACL::debug = ->
        if debug.enabled
          debug '---ACL---'
          debug 'model %s', @model
          debug 'methodName %s', @methodName
          debug 'principalType %s', @principalType
          debug 'principalId %s', @principalId
          debug 'accessType %s', @accessType
          debug 'permission %s', @permission
          debug 'with score: %s', @score

        return

      ACL

    @factory 'AccessHandler', (OAuthError, ServerError, AccessDeniedError, InvalidArgumentError, AccessContext, AccessReq, AccessRes) ->

      class AccessHandler
        constructor: (options) ->
          for key, value of options
            @[key] = value

          @authenticateHandler = new AuthenticateHandler
            addAcceptedScopesHeader: true
            addAuthorizedScopesHeader: true
            allowBearerTokensInQueryString: false

        handle: (request, response) ->
          if not request instanceof Request
            throw new InvalidArgumentError 'REQUEST'

          if not response instanceof Response
            throw new InvalidArgumentError 'RESPONSE'

          Promise.bind this
            .then ->
              @accessContext.checkAccess
            .then (@allowed) ->
              @getAuth request, response
            .then (token) ->
              @afterAuth request, token
            .catch (e) ->
              if not e instanceof OAuthError
                e = new ServerError e

              throw e

              return

        getAuth: (request, response) ->
          if @allowed
            return Promise.resolve @allowed

          @authenticateHandler.handle request, response
            .then (token) ->
              if not token.userId and not token.roles
                throw new ServerError 'USEROBJECT'

              token

        afterAuth: (request, token) ->
          if @allowed
            return Promise.resolve @allowed

          if not token
            throw new AccessDeniedError 'NOACCESS'

          @accessContext.setToken token

          request.accessContext = @accessContext

          @accessContext.checkAccess
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

        context = new AccessContext
          modelName: parent.name
          modelId: modelId
          methodName: name

        context.setAccessTypeForRoute route

        new AccessHandler context
          .handle request, response
          .tap ->
            req.accessContext = request.accessContext
          .asCallback next
