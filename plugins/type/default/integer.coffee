
module.exports = ->

  @type 'Integer', (Type) ->
    class Integer extends Type
      @check: (v) ->
        return false if @absent v

        @integer v

      @parse: (v) ->
        if @integer v
          return v

        if @float v
          return parseInt v

        pv = parseInt v

        if @integer pv
          pv
        else undefined
