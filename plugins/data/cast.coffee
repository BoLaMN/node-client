module.exports = ->

  @factory 'Cast', (Types, Models, injector, utils) ->
    { buildOptions } = utils

    class Cast

      apply: (value, name, ctx, index) ->
        if not value?
          return null

        type = @type 

        if index 
          type = @type[index] or @type[0]

        fn = Models.get type
        fn ?= Types.get type

        if fn.prototype instanceof injector.get 'Model' 
          options = buildOptions ctx.instance, name, index

        if typeof fn?.parse is 'function'
          return fn.parse value, options
        
        if fn
          return fn value
        
        return value
