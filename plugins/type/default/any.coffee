
module.exports = ->

  @type 'Any', (Type) ->
    class Any extends Type
      @check: (v) ->
        @present v
