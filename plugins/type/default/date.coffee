
module.exports = ->

  @type 'Date', (Type) ->
    class Date extends Type
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
