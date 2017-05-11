
module.exports = ->

  @type 'Number', (Type, Types) ->

    class Number extends Types.float

      @swagger:

        schema: (v) ->
          type: 'number'
          format: 'double'

      @check: (v) ->
        super

      @parse: (v) ->
        if @number v
          return v

        super
