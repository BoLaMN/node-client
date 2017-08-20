
module.exports = ->

  @type 'Array', (Type, injector) ->
    class Array extends Type
      @construct: (itemType) ->
        ctor = @extends @name, @
        ctor.itemType = itemType
        ctor

      @swagger:

        schema: (v) ->
          swagger = injector.get 'swagger'
          item = v.type[0] or 'any'

          type: 'array'
          items: swagger.buildFromSchemaType item

      @check: (v) ->
        return false if @absent v

        if not @array v
          return false

        if not @itemType
          return true

        i = 0

        while i < v.length
          if not @itemType.check(v[i])
            return false
          i++

        true

      @parse: (v) ->
        if @array v and not @itemType
          return v

        if not @array v
          return [ v ]

        i = 0

        while i < v.length
          v[i] = @itemType.parse v[i]
          i++

        v
        
