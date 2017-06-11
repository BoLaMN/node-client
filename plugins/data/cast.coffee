module.exports = ->

  @factory 'Cast', (Types, Models, Utils) ->
    { buildOptions } = Utils

    class Cast

      apply: (value, name, ctx, index) ->
        if not value?
          return null

        if index 
          @fn ?= []
          
          type = @type[index] or @type[0]

          fn = Models.get type
          fn ?= Types.get type

          @fn[index] ?= fn
        else
          fn = Models.get @type
          fn ?= Types.get @type

          @fn = fn 

        if typeof fn?.parse is 'function'
          options = buildOptions ctx.instance, name, index
          return fn.parse value, options
        else if fn
          return fn value
        else
          return value
