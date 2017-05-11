
module.exports = ->

  @type 'Json', (Type) ->
    class Json extends Type
      @check: (value) ->
        return false if not @string value

        start = value[0]
        end = value[value.length - 1]

        array = start is '[' and end is ']'
        object = start is '{' and end is '}'

        array or object

      @parse: (value) ->
        if not @check value
          return value

        JSON.parse value
