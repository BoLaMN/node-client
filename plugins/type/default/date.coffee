
module.exports = ->

  @type 'Date', (Type) ->
    class Date extends Type

      @swagger:

        schema: (v) ->
          type: 'string'
          format: 'date-time'

      @check: (v) ->
        return false if @absent v

        @date v

      @parse: (v) ->
        if @date v
          return v

        date = Date v
        time = date?.getTime?()

        if @present v and @integer time
          date
        else undefined
