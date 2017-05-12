toFunction = require './ToFunction'

module.exports = ->

  @factory 'filter', ->
    (array, predicate) ->
      fn = toFunction predicate
      array.filter fn

  @factory 'remove', ->
    (array = [], value) ->
      if not Array.isArray array
        return -1

      index = array.indexOf value

      if index >= 0
        array.splice index, 1

      index

  @factory 'isArguments', (baseGetTag)->
    (value) -> typeof value is 'object' and
               value isnt null and
               baseGetTag(value) is '[object Arguments]'

  @factory 'isNull', ->
    (value) -> value is null

  @factory 'isNumber', (baseGetTag, isObjectLike) ->
    (value) -> typeof value is 'number' or
               isObjectLike(value) and baseGetTag(value) is '[object Number]'

  @factory 'isBoolean', (baseGetTag, isObjectLike) ->
    (value) -> value is true or
               value is false or
               isObjectLike(value) and baseGetTag(value) is '[object Boolean]'

  @factory 'isPrototype', ->
    (value) ->
      Ctor = value?.constructor
      value is typeof Ctor is 'function' and Ctor.prototype or Object.prototype

  @factory 'isArrayLike', (isLength) ->
    (value) ->
      value isnt null and
      typeof value isnt 'function' and
      isLength value.length

  @factory 'isArrayLikeObject', (isObjectLike, isArrayLike) ->
    (value) ->
      isObjectLike(value) and isArrayLike(value)

  @factory 'isLength', ->
    (value) ->
      typeof value is 'number' and
      value > -1 and
      value % 1 is 0 and
      value <= 9007199254740991

  @factory 'isEmpty', (isArrayLike, isArguments, isPrototype) ->
    (value) ->
      if not value?
        return true

       hasValue = isArrayLike(value) and
                  Array.isArray(value) or
                  typeof value is 'string' or
                  typeof value.splice is 'function' or
                  isArguments value

       if hasValue
        return not value.length

      if isPrototype(value)
        return not Object.keys(value).length

      for key of value
        if hasOwnProp.call(value, key)
          return false

      true

  @factory 'isUndefined', ->
    (value) -> value is undefined

  @factory 'isDefined', ->
    (value) -> value isnt undefined

  @factory 'isObjectLike', ->
    (value) -> typeof value is 'object' and value isnt null

  @factory 'isObject', ->
    (value) ->
      type = typeof value

      value isnt null and (type is 'object' or type is 'function')

  @factory 'isObjectLike', ->
    (value) -> typeof value is 'object' and value isnt null

  @factory 'hasOwnProp', ->
    (ctx, val) -> Object::hasOwnProperty.call ctx, val

  @factory 'objToString', ->
    (value) -> Object::toString.call value

  @factory 'baseGetTag', (hasOwnProp, objToString) ->
    symToStringTag = if typeof Symbol isnt 'undefined' then Symbol.toStringTag else undefined

    (value) ->
      if value is null
        return if value is undefined then '[object Undefined]' else '[object Null]'

      if not (symToStringTag and symToStringTag of Object(value))
        return objToString value

      isOwn = hasOwnProp value, symToStringTag
      tag = value[symToStringTag]

      unmasked = false

      try
        value[symToStringTag] = undefined
        unmasked = true
      catch e

      result = objToString value

      if unmasked
        if isOwn
          value[symToStringTag] = tag
        else
          delete value[symToStringTag]

      result

  @factory 'isDate', (isObjectLike, baseGetTag) ->
    (value) -> isObjectLike(value) and baseGetTag(value) is '[object Date]'

  @factory 'isRegExp', (isObjectLike, baseGetTag) ->
    (value) -> isObjectLike(value) and baseGetTag(value) is '[object RegExp]'

  @factory 'isString', (baseGetTag) ->
    (value) ->
      type = typeof value

      type is 'string' or
      type is 'object' and
      value isnt null and
      not Array.isArray(value) and
      baseGetTag(value) is '[object String]'

  @factory 'isFunction', (isObject, baseGetTag) ->
    (value) ->
      if not isObject value
        return false

      tag = baseGetTag value

      tag is '[object Function]' or
      tag is '[object AsyncFunction]' or
      tag is '[object GeneratorFunction]' or
      tag is '[object Proxy]'

  @factory 'isPlainObject', (isObjectLike, baseGetTag, objToString, hasOwnProp) ->
    (value) ->
      if not isObjectLike(value) or baseGetTag(value) isnt '[object Object]'
        return false

      proto = Object.getPrototypeOf value
      objectCtorString = objToString Object

      if proto is null
        return true

      Ctor = hasOwnProp(proto, 'constructor') and proto.constructor

      typeof Ctor is 'function' and Ctor instanceof Ctor and objToString(Ctor) is objectCtorString

  @factory 'baseExtend', (isObject, isFunction, isRegExp, isDate) ->
    (dst, objs, deep) ->
      i = 0
      ii = objs.length

      while i < ii
        obj = objs[i]

        if not isObject(obj) and not isFunction(obj)
          ++i
          continue

        keys = Object.keys(obj)

        j = 0
        jj = keys.length

        while j < jj
          key = keys[j]
          src = obj[key]

          if deep and isObject(src)
            if isDate(src)
              dst[key] = new Date(src.valueOf())
            else if isRegExp(src)
              dst[key] = new RegExp(src)
            else
              if not isObject(dst[key])
                dst[key] = if Array.isArray(src) then [] else {}

              baseExtend dst[key], [ src ], true
          else
            dst[key] = src

          j++

        ++i

      dst

  @factory 'extend', (baseExtend) ->
    (dst, objs...) ->
      baseExtend dst, objs, false

  @factory 'merge', (baseExtend) ->
    (dst, objs...) ->
      baseExtend dst, objs, true
