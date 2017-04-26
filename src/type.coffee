class Type
  @inspect: ->
    @name

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

class exports.String extends Type
  @cast: (v) ->
    return if @absent v

    if @string v
      return v
    else
      return @coerce v

  @coerce: (v) ->
    if v?.toString?()
      new @cast v.isString()
    else undefined

class exports.Boolean extends Type
  @cast: (v) ->
    return if @absent v

    if @boolean v
      return v
    else
      return @coerce v

  @coerce: (v) ->
    parseFloat v > 0 or
    @infinite v or
    v in [ '1', 'true', 'yes', '+' ] or
    undefined

class exports.Integer extends Type
  @cast: (v) ->
    return if @absent v

    if @integer v
      return v
    else
      return @coerce v

  @coerce: (v) ->
    if @float v
      return parseInt v

    pv = parseInt v

    if @integer pv
      pv
    else undefined

class exports.Float extends Type
  @cast: (v) ->
    return if @absent v

    if @float v
      return v
    else
      return @coerce v

  @coerce: (v) ->
    pv = parseFloat v

    if @float pv
      pv
    else undefined

class exports.Any
  @cast: (v) ->
    return if @absent v

    return v

class exports.Number extends exports.Float
  @cast: (v) ->
    return if @absent v

    if @float v
      return v
    else
      return @coerce v

class exports.Date extends Type
  @cast: (v) ->
    return if @absent v

    if @date v
      return v
    else
      return @coerce v

  @coerce: (v) ->
    date = new Date v
    time = date?.getTime?()

    if @present v and @integer time
      date
    else undefined

class exports.Array
  @cast: (v) ->
    if @array v
      return v
    else
      return @coerce v

  @coerce: (v) ->
    if @value v
      [ v ]
    else undefined

exports.Type = Type
