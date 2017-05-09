debug = require('debug')('security:acl')

module.exports = (app) ->

  app.module 'Access', [ ]

  .initializer ->

    @include './errors'
    @include './access-context'
    @include './principal'
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
          debug 'model %s', @modelName
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
        constructor: (req, res) ->
          @request = new AccessReq req
          @response = new AccessRes res

          if not @request instanceof AccessReq
            return Promise.reject new InvalidArgumentError 'REQUEST'

          if not @response instanceof AccessRes
            return Promise.reject new InvalidArgumentError 'RESPONSE'

          { params, query, body, route } = req
          { method, name, modelName } = route

          modelId = params.id or body.id or query.id

          @context = new AccessContext
            modelName: modelName
            modelId: modelId
            methodName: name

          @context.setAccessTypeForRoute route

          @authenticateHandler = handle: ->
            Promise.resolve userId: '1', roles: []

        @check: (req, res) ->
          handler = new AccessHandler req, res

          handler.getAuth()

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
