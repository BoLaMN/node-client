module.exports = ->

  @factory 'Context', (utils, injector) ->
    { getArgs } = utils 

    class Context
      constructor: (@model, @cmd, args...) ->
        @hookState = {}
        @context = []

        { @dao } = @model 

        @args = getArgs @dao[@cmd]

        @setup args

        return @execute()

      clone: (data, idx) ->
        if @context[idx]
          return @context[idx]

        if data instanceof injector.get 'Model'
          instance = data 
        else
          instance = new @model data

        if @id
          idName = @model.primaryKey

          if not data[idName]
            instance.setId @id 

        hookState = {}
        isNewInstance = @cmd is 'create'

        @context[idx] = { data, instance, hookState, isNewInstance }

        names = [ 'context', 'filter', 'options', 'model' ]
        
        for name in names when @[name]?
          @context[idx][name] = @[name]

        @context[idx]

      setup: (args) ->

        for arg, idx in @args
          @[arg] = args[idx]

        if @id
          idName = @model.primaryKey

          @where ?= {}
          @where[idName] = @id

        Promise.resolve()

      execute: ->

        fns = [
          'before'
          'validate'
          'persist'
          'run'
          'loaded'
          'after'
        ]

        current = Promise.resolve()

        promises = fns.map (fn) =>
          current = current.then (res) =>
            @[fn] res
          current

        Promise.all(promises).then =>
          @data

      run: ->
        args = []

        for arg, idx in @args
          args[idx] = @[arg]

        @dao[@cmd] args...

      strict: ->
        props = @model.attributes

        for key of @data when not props[key]
          delete @data[key]

      before: ->
        @notify 'before ' + @cmd

      after: ->
        @notify 'after ' + @cmd

      loaded: (res) ->
        @data = res 

        @notify 'loaded'

      persist: ->
        @notify 'persist'

      notify: (event) ->
        if Array.isArray @data
          Promise.each @data, (data, idx) =>
            @model.fire event, @clone(data, idx)
        else 
          @model.fire event, @clone(@data, 0)

      validate: ->
        @notify 'validate'
