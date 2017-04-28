'use strict'

class exports.Type
  constructor: ->

  parse: (string) ->
    string

  check: (value) ->
    true

  toString: ->
    @name

class exports.RegExp extends exports.Type
  constructor: (re) ->
    @re = re
    return

  parse: (value) ->
    value.toString()

  check: (value) ->
    if typeof value != 'string'
      return false

    value = value.toString()
    match = value.match(@re)
    match and value == match[0]

  toString: ->
    (if @name then @name + ' ' else '') + @re.toString()

class exports.Json extends exports.Type
  constructor: ->

  parse: (string) ->
    JSON.parse string

class exports.Array extends exports.Json
  constructor: (itemType) ->
    @itemType = itemType

  check: (value) ->
    if !Array.isArray(value)
      return false

    if !@itemType
      return true

    i = 0

    while i < value.length
      if !@itemType.check(value[i])
        return false
      i++

    true

class exports.String extends exports.Type
  constructor: ->

  check: (value) ->
    typeof value == 'string'

class exports.Number extends exports.Type
  constructor: ->

  parse: (string) ->
    value = parseFloat(string)

    if isNaN(value)
      throw new TypeError('Could not parse string as number')

    value

  check: (value) ->
    typeof value == 'number' or !isNaN(parseFloat(value))

class exports.Integer extends exports.Type
  constructor: (min, max) ->
    @min = if min == undefined then Number.MIN_VALUE else min
    if @max - max == undefined then Number.MAX_VALUE else max

  parse: (string) ->
    parseInt string, 10

  check: (value) ->
    typeof value == 'number' and Math.round(value) == value

class exports.Boolean extends exports.Type
  constructor: ->

  parse: (string) ->
    if string != 'true' and string != 'false'
      throw new Error('Could not parse \'' + string + '\' as a boolean')

    string == 'true'

  check: (value) ->
    typeof value == 'boolean'

module.exports = ->

  @factory 'Types', ->
    class Types
      constructor: ->
        @types = {}

        @register 'string', new exports.String
        @register 'number', new exports.Number
        @register 'boolean', new exports.Boolean
        @register 'int', new exports.Integer
        @register 'json', new exports.Json
        @register 'array', new exports.Array
        @register 'array[string]', new exports.Array new exports.String

      register: (name, type) ->
        type.name = name

        if type instanceof RegExp
          type = new exports.RegExp type

        @types[name] = type

        this

      get: (name) ->
        if name.check and name.parse
          return name

        type = @types[name]

        if !type
          throw new Error('Unknown type ', name)

        type
