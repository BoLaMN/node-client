Storage = require './storage'
buildOptions = require './utils/build-options'

isUndefined = (v) ->
  typeof v is 'undefined' or v is undefined

isNull = (v) ->
  v is null

isInfinite = (v) ->
  v is Infinity

isValue = (v) ->
  not isUndefined(v) and not isNull(v) and not (isNumber(v) and isNaN(v)) and not isInfinite(v)

isString = (v) ->
  typeof v is 'string'

isBoolean = (v) ->
  typeof v is 'boolean'

isNumber = (v) ->
  typeof v is 'number'

isInteger = (v) ->
  if isNumber(v) then v % 1 is 0 else false

isFloat = (v) ->
  isNumber(v) and isFinite(v)

isDate = (v) ->
  not isUndefined(v) and not isNull(v) and v.constructor is Date and isInteger(v.getTime())

isObject = (v) ->
  not isUndefined(v) and not isNull(v) and v.constructor is Object

isArray = (v) ->
  Array.isArray v

isAbsent = (v) ->
  isUndefined(v) or
  isNull(v) or
  isNumber(v) and isNaN(v) or
  isString(v) and v is '' or
  isArray(v) and not v.length or
  isObject(v) and not Object.keys(v).length

isPresent = (v) ->
  not isAbsent(v)

isFunction = (v) ->
  typeof v is 'function'

isClass = (v) ->
  isFunction v

isPromise = (v) ->
  isPresent(v) and v.constructor and v.constructor.name is 'Promise'

toString = (v) ->
  if isString(v)
    v
  else if isUndefined(v) or isNull(v)
    null
  else
    toString v.toString()

toBoolean = (v) ->
  if isBoolean(v)
    v
  else if isUndefined(v) or isNull(v)
    null
  else
    parseFloat(v) > 0 or
    isInfinite(v) or
    v in [ '1', 'true', 'yes', '+' ]

toInteger = (v) ->
  if isInteger(v)
    v
  else if isUndefined(v) or isNull(v)
    null
  else if isFloat(v)
    parseInt v
  else
    pv = parseInt(v)

    if isInteger(pv)
      pv
    else if toBoolean(v)
      1
    else
      0

toFloat = (v) ->
  if isFloat(v)
    v
  else if isUndefined(v) or isNull(v)
    null
  else
    pv = parseFloat(v)

    if isFloat(pv)
      pv
    else if toBoolean(v)
      1
    else 0

toNumber = (v) ->
  toFloat v

toDate = (v) ->
  date = if isDate(v) then v else new Date(v)
  time = date.getTime()

  isValid = isPresent(v) and isInteger(time)

  if isValid then date else null

toArray = (v) ->
  if isArray(v)
    v
  else if not isValue(v)
    []
  else
    [ v ]

types = new Storage
  any: (v) -> v
  string: toString
  boolean: toBoolean
  integer: toInteger
  float: toFloat
  number: toNumber
  date: toDate

class Cast

  @defineType: (type, names = []) ->

    define = (n, t) ->
      types.$define n.toLowerCase(), t or type

    names.forEach define

    define type.name, type

  apply: (name, value, instance, index) ->
    if not isValue value
      return null

    { models } = instance.constructor

    @fn ?= models.$get @type
    @fn ?= types.$get @type

    if isArray @type
      return toArray(value).map (val, i) =>
        @apply name, val, instance, i
    else if @fn?.modelName
      options = buildOptions instance, name, index
      return new @fn value, options
    else if isFunction @fn
      return @fn value
    else
      return value

module.exports = Cast