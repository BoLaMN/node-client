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

          for name, route of routes.bind(config)()
            route.args = Object.keys route.params
            route.args.push 'cb'

            @remoteMethod name, route, section, (args..., cb) ->
              data = {}

              for arg, idx in args
                data[@args[idx]] = arg

              primaryKey = data[config.primaryKey]
              foreignKey = data[config.foreignKey]

              instance = new model
              instance.setId primaryKey
              instance[@parent.name][@name] foreignKey, {}, cb

        @

      @remoteMethod: (name, config, section, fn) ->
        route = section or api.section @modelName

        fn ?= Utils.get @, name

        if not fn
          console.error "method #{name} not found on #{ @modelName }"
          return

        config.args ?= Utils.getArgs fn

        route[config.method] name, config, fn