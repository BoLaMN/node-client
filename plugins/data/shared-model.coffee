module.exports = ->

  @include './routes'

  @factory 'SharedModel', (PersistedModel, api, Utils, injector, Routes) ->

    class SharedModel extends PersistedModel

      @configure: (@modelName, attributes) ->
        super

        for name, config of Routes.bind(@)()
          @remoteMethod name, config

        @relations.on '*', (rel, config) =>
          routes = injector.get(config.$type + 'Routes') or
                   injector.get 'RelationRoutes'

          parent = api.section @modelName
          section = parent.section rel
          model = @

          for method, route of routes.bind(config)()
            route.args = Object.keys route.params
            route.args.push 'cb'

            fn = (args...) ->
              console.log 'shared model', args

              data = {}

              for arg, idx in route.args
                data[arg] = args[idx]

              args.shift()

              primaryKey = data[config.primaryKey]
              foreignKey = data[config.foreignKey]

              instance = new model
              instance.setId primaryKey

              relation = instance[config.as]
              relation[method].apply relation, args

              return

            @remoteMethod method, route, section, fn.bind @

          return

        @

      @remoteMethod: (name, config, section, fn) ->
        route = section or api.section @modelName

        fn ?= Utils.get @, name

        if not fn
          console.error "method #{name} not found on #{ @modelName }"
          return

        config.args ?= Utils.getArgs fn

        route[config.method] name, config, fn.bind @