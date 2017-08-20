
module.exports = ->

  @type 'Object', (Type, Types, injector) ->

    class Object extends Types.json
      @check: (value) ->
        if @string value
          super
        else
          @object value

      @swagger:

        schema: (v) ->
          if v.source is 'query'
            type: 'string'
          else if v.model
            swagger = injector.get 'swagger'
            
            obj = {}

            for prop, val of v.model
              obj[prop] = swagger.buildFromSchemaType val

            type: 'object'
            properties: obj
          else
            type: 'object'