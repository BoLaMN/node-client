class Type

  @undefined: (v) ->
    typeof v is 'undefined' or
    v is undefined

  @null: (v) ->
    v is null

  @infinite: (v) ->
    v is Infinity

  @value: (v) ->
    not @undefined v and
    not @null v and
    not (@number v and @nan v) and
    not @infinite v

  @string: (v) ->
    typeof v is 'string'

  @boolean: (v) ->
    typeof v is 'boolean'

  @number: (v) ->
    typeof v is 'number'

  @integer: (v) ->
    if @number v then v % 1 is 0 else false

  @float: (v) ->
    @number v and isFinite v

  @date: (v) ->
    not @undefined v and
    not @null v and
    v is Date and
    @integer v.getTime()

  @object: (v) ->
    not @undefined v and
    not @null v and
    v is Object

  @array: (v) ->
    Array.isArray v

  @absent: (v) ->
    @undefined v or
    @null v or
    @number v and
    @nan v or
    @string v and
    v is '' or
    @array v and
    not v.length or
    @object v and
    not Object.keys v.length

  @present: (v) ->
    not @absent v

  @function: (v) ->
    typeof v is 'function'

  @class: (v) ->
    @function v

  @promise: (v) ->
    @present v and v?.name is 'Promise'

  @parse: (string) ->
    string

  @check: (value) ->
    true

  @toString: ->
    @name

  @inspect: ->
    @name

class exports.String extends Type
  @check: (v) ->
    return false if @absent v

    @string v

  @parse: (v) ->
    if @string v
      return v

    if v?.toString?()
      @check v.isString()
    else undefined

class exports.Boolean extends Type
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

class exports.Integer extends Type
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

class exports.Float extends Type
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

class exports.Any extends Type
  @check: (v) ->
    @absent v

class exports.Number extends exports.Float
  @check: (v) ->
    super

  @parse: (v) ->
    if @number v
      return v

    super

class exports.Date extends Type
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

class exports.Array extends Type
  @construct: (itemType) ->
    class Instance extends @

    Instance.itemType = itemType
    Instance

  @check: (v) ->
    return false if @absent v

    if not @array v
      return false

    if not @itemType
      return true

    i = 0

    while i < v.length
      if not @itemType.check(v[i])
        return false
      i++

    true

  @parse: (v) ->
    if @array v and not @itemType
      return v

    if not @array v
      return [ v ]

    i = 0

    while i < v.length
      v[i] = @itemType.parse v[i]
      i++

    v

class exports.RegExp extends Type
  @construct: (re) ->
    class Instance extends @

    Instance.re = re
    Instance

  @parse: (value) ->
    value.toString()

  @check: (value) ->
    return false if not @string value

    value = value.toString()
    match = value.match @re

    match and value is match[0]

  toString: ->
    (if @name then @name + ' ' else '') + @re.toString()

class exports.Json extends Type
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

module.exports = ->

  @factory 'Type', ->
    Type

  @factory 'Types', (Storage) ->

    class Types extends Storage
      constructor: ->

        @define 'string', exports.String
        @define 'number', exports.Number
        @define 'boolean', exports.Boolean
        @define 'integer', exports.Integer
        @define 'json', exports.Json
        @define 'object', exports.Json
        @define 'array', exports.Array
        @define 'date', exports.Date
        @define 'float', exports.Float
        @define 'regexp', exports.RegExp
        @define 'any', exports.Any
        @define 'array[string]', exports.Array.construct exports.String

    new Types
