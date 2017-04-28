Storage = require './storage'
Type = require './type'

buildOptions = require './utils/build-options'

types = new Storage Type

class Cast

  @defineType: (type, names = []) ->

    define = (n, t) ->
      types.$define n.toLowerCase(), t or type

    names.forEach define

    define type.name, type

  apply: (name, value, instance, index) ->
    if not value?
      return null

    { models } = instance.constructor

    @fn ?= models.$get @type
    @fn ?= types.$get @type

    if Array.isArray @type
      return new Type.Array(value).map (val, i) =>
        @apply name, val, instance, i
    else if @fn?.modelName
      options = buildOptions instance, name, index
      return new @fn value, options
    else if typeof @fn?.cast is 'function'
      return @fn.cast value
    else if @fn
      return @fn value
    else
      return value

module.exports = Cast