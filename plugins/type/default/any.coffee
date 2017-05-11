
module.exports = ->

  @type 'Any', (Type) ->

    class Any extends Type

      @swagger:

        definition: (v) ->
          properties: {}

        schema: (v) ->
          if v.source is 'path'
            type: 'string'
          else
            $ref: '#/definitions/any'

      @check: (v) ->
        @present v
