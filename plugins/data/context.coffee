module.exports = ->

  @factory 'Context', (Utils) ->
    { getArgs } = Utils 

    class Context
      constructor: (@model, @cmd, args...) ->
        @hookState = {}
        
        { @dao } = @model 

        @args = getArgs @dao[@cmd]

        @setup args

        return @execute()

      setup: (args) ->

        for arg, idx in @args
          @[arg] = args[idx]

        if @data and not @instance
          @instance = new @model @data

        if @id
          idName = @model.primaryKey

          if not @data[idName]
            @instance.setId id 

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

        Promise.all(promises).then @finish

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

      finish: (res) ->
        @instance
        
      loaded: (res) ->
        @results = res 
        @notify 'loaded'

      persist: ->
        @notify 'persist'

      notify: (event) ->
        @model.fire event, @

      validate: ->
        @notify 'validate'
