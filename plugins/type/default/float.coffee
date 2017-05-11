
module.exports = ->

  @type 'Float', (Type) ->
    class Float extends Type
      @check: (v) ->
        return false if @absent v

        @float v

      @parse: (v) ->
        if @float v
          return v

        pv = parseFloat v

        if @float pv
          pv
        else undefined
