module.exports = ->

  @include './routes'

  @factory 'SharedModel', (PersistedModel, api, Utils, injector, Routes) ->

    class SharedModel extends PersistedModel

      @configure: (@modelName, attributes) ->
        super

        for name, config of Routes.bind(@)()
          @remoteMethod name, config

        @relations.on '*', (rel, config) =>
          specific = injector.get config.$type + 'Routes'
          defaults = injector.get 'RelationRoutes'

          parent = api.section @modelName

          add = (routes) =>
            Object.keys(routes).forEach (name) =>
              route = routes[name]

              route.args = Object.keys route.params
              route.args.push 'cb'

              route.path = '/' + @modelName + route.path
              route.modelName = config.to.modelName or @modelName

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

          add defaults.bind(config)()

          if specific
            add specific.bind(config)()

        @

      @remoteMethod: (name, config, section, fn) ->
        route = section or api.section @modelName

        fn ?= Utils.get @, name

        if not fn
          console.error "method #{name} not found on #{ @modelName }"
          return

        config.args ?= Utils.getArgs fn
        config.path = '/' + @modelName + config.path

        config.modelName = @modelName

        route[config.method] name, config, fn.bind @