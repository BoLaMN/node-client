
module.exports = ->

  @type 'Number', (Type, Types) ->
    class Number extends Types.float
      @check: (v) ->
        super

      @parse: (v) ->
        if @number v
          return v

        super
