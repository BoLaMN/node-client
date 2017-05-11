
module.exports = ->

  @type 'Boolean', (Type) ->
    class Boolean extends Type
      @check: (v) ->
        return false if @absent v

        @boolean v

      @parse: (v) ->
        if @boolean v
          return v

        parseFloat v > 0 or
        @infinite v or
        v in [ '1', 'true', 'yes', '+' ] or
        undefined
