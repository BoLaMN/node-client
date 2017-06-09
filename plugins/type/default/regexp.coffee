
module.exports = ->

  @type 'RegExp', (Type) ->
    class RegExp extends Type
      @construct: (re) ->
        ctor = @extends @name, @
        ctor.re = re
        ctor

      @parse: (value) ->
        value.toString()

      @check: (value) ->
        return false if not @string value

        value = value.toString()
        match = value.match @re

        match and value is match[0]

      toString: ->
        (if @name then @name + ' ' else '') + @re.toString()
