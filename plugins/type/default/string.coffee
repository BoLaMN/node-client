
module.exports = ->

  @type 'String', (Type) ->
    class String extends Type
      @check: (v) ->
        return false if @absent v

        @string v

      @parse: (v) ->
        if @string v
          return v

        if v?.toString?()
          @check v.isString()
        else undefined
