module.exports = ->

  @include './routes'

  @factory 'SharedModel', (PersistedModel, api, Utils, injector, Routes) ->

    class SharedModel extends PersistedModel

      @configure: (attributes) ->
        super

        for name, config of Routes.bind(@)()
          @remoteMethod name, config

        @relations.on '*', (rel, config) =>
          defaults = injector.get 'RelationRoutes'
          through = injector.get 'ThroughRoutes'

          parent = api.section @name

          add = (routes) =>

            Object.keys(routes).forEach (name) =>
              route = routes[name]

              route.args = Object.keys route.params
              route.args.push 'cb'

              route.path = '/' + @name + route.path
              route.modelName = config.model.name or @name

              fn = (args...) ->
                data = {}

                for arg, idx in route.args
                  data[arg] = args[idx]

                args.shift()

                primaryKey = data[config.primaryKey]
                foreignKey = data[config.foreignKey]

                instance = new @
                instance.setId primaryKey

                relation = instance[config.as]
                relation[name].apply relation, args

                return

              section = parent.section rel, route.path
              section[route.method] name, route, fn.bind @

            return

          add defaults.bind(config)(@)

          if config.through or config.type is 'referencesMany'
            add through.bind(config)(@)

          specific = config.$type + 'Routes'

          if injector.has specific
            add injector.get(specific).bind(config)(@)

        @

      @remoteMethod: (name, config, section, fn) ->
        route = section or api.section @name

        fn ?= Utils.get @, name

        if not fn
          console.error "method #{name} not found on #{ @name }"
          return

        config.args ?= Utils.getArgs fn
        config.path = '/' + @name + config.path

        config.modelName = @name

        route[config.method] name, config, fn.bind @