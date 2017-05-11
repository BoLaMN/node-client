
module.exports = ->

  @type 'Buffer', (Type) ->

    class Instance extends Buffer

      @swagger:

        schema: (v) ->
          type: 'string'
          format: 'byte'

      @check: (v) ->
        v instanceof Buffer
