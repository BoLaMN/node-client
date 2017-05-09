module.exports = ->

  @factory 'AccessPrincipal', ->

    class AccessPrincipal
      constructor: (@type, @id, @name) ->
        return

      @USER: 'User'
      @APP: 'Application'
      @ROLE: 'Role'
      @SCOPE: 'Scope'

      ###*
      # Compare if two principals are equal
      # Returns true if argument principal is equal to this principal.
      # @param {Object} p The other principal
      ###

      equals: (p) ->
        if p instanceof AccessPrincipal
          return @type is p.type and String(@id) is String(p.id)
        false
