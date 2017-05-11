
module.exports = ->

  @type 'Object', (Type, Types) ->

    class Object extends Types.json

      @swagger:

        schema: (v) ->
          if v.source is 'query'
            type: 'string'
          else
            type: 'object'
