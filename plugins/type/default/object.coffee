
module.exports = ->

  @type 'Object', (Type, Types) ->

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
          else
            type: 'object'
