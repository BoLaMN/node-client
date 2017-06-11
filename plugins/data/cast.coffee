module.exports = ->

  @factory 'Cast', (Types, Models, Utils) ->
    { buildOptions } = Utils

    class Cast

      apply: (value, name, ctx, index) ->
        if not value?
          return null

        type = @type 

        if index 
          type = @type[index] or @type[0]

        fn = Models.get type
        fn ?= Types.get type
        
        if typeof fn?.parse is 'function'
          options = buildOptions ctx.instance, name, index
          return fn.parse value, options
        else if fn
          return fn value
        else
          return value
