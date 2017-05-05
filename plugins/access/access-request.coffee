debug = require('debug')('security:acl')

module.exports = ->

  @factory 'AccessRequest', (AccessContext, injector) ->

    class AccessRequest
      constructor: (context) ->
        @model = AccessContext.ALL
        @property = AccessContext.ALL
        @accessType = AccessContext.ALL
        @permission = AccessContext.DEFAULT
        @methodNames = []

        for own key, value of context
          @[key] = value

        return

      ###*
      # Does the request contain any wildcards?
      #
      # @returns {Boolean}
      ###

      isWildcard: ->
        @model is AccessContext.ALL or
        @property is AccessContext.ALL or
        @accessType is AccessContext.ALL

      ###*
      # Does the given `ACL` apply to this `AccessRequest`.
      #
      # @param {ACL} acl
      ###

      exactlyMatches: ({ model, property, accessType }) ->
        matchesModel = model is @modelName
        matchesProperty = property is @property

        matchesMethodName = @methodNames.indexOf(property) != -1
        matchesAccessType = accessType is @accessType

        if matchesModel and matchesAccessType
          return matchesProperty or matchesMethodName

        false

      ###*
      # Is the request for access allowed?
      #
      # @returns {Boolean}
      ###

      isAllowed: ->
        @permission isnt AccessContext.DENY

      debug: ->
        if debug.enabled
          debug '---AccessRequest---'
          debug ' model %s', @modelName
          debug ' property %s', @property
          debug ' accessType %s', @accessType
          debug ' permission %s', @permission
          debug ' isWildcard() %s', @isWildcard()
          debug ' isAllowed() %s', @isAllowed()

        return
