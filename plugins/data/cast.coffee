module.exports = ->

  @factory 'Cast', (Types, Models, buildOptions) ->

    class Cast

      apply: (name, value, instance, index) ->
        if not value?
          return null

        { models } = instance.constructor

        @fn ?= Models.$get @type
        @fn ?= Types.$get @type

        if Array.isArray @type
          return new Type.Array(value).map (val, i) =>
            @apply name, val, instance, i
        else if @fn?.modelName
          options = buildOptions instance, name, index
          return new @fn value, options
        else if typeof @fn?.parse is 'function'
          return @fn.parse value
        else if @fn
          return @fn value
        else
          return value
