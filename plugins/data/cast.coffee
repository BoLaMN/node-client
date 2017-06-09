module.exports = ->

  @factory 'Cast', (Types, Models, Utils) ->
    { buildOptions } = Utils

    class Cast

      apply: (value, name, instance, index) ->
        if not value?
          return null

        @fn ?= Models.get @type
        @fn ?= Types.get @type

        if Array.isArray @type
          return new Type.Array(value).map (val, i) =>
            @apply name, val, instance, i
        else if typeof @fn?.parse is 'function'
          options = buildOptions instance, name, index
          return @fn.parse value, options
        else if @fn
          return @fn value
        else
          return value
