module.exports = ->

  routes =

    destroy:
      params:
        where:
          description: "filter.where object"
          type: "object"
          source: 'query'
        options:
          type: 'object'
          source: 'context'
          optional: true
      accessType: "WRITE"
      description: "Delete all matching records."
      path: "/"
      method: "delete"

    destroyById:
      params:
        id:
          description: "Model id"
          source: "url"
          type: "any"
        options:
          type: 'object'
          source: 'context'
          optional: true
      accessType: "WRITE"
      aliases: [
        "destroyById"
        "removeById"
      ]
      description: "Delete a model instance by id from the data source."
      path: "/:id"
      method: "del"

    create:
      params:
        data:
          description: "Model instance data"
          source: "body"
          type: "object"
          optional: true
        options:
          type: 'object'
          source: 'context'
          optional: true
      accessType: "WRITE"
      description: "Create a new instance of the model and persist it into the data source."
      path: "/"
      method: "post"

    count:
      params:
        where:
          description: "Criteria to match model instances"
          type: "object"
          optional: true
          source: 'query'
        options:
          type: 'object'
          source: 'context'
          optional: true
      accessType: "READ"
      description: "Count instances of the model matched by where from the data source."
      path: "/count"
      method: "get"

    exists:
      params:
        id:
          description: "Model id"
          type: "any"
          source: 'url'
        options:
          type: 'object'
          source: 'context'
          optional: true
      accessType: "READ"
      description: "Check whether a model instance exists in the data source."
      path: "/:id"
      method: "head"

    find:
      params:
        filter:
          description: "Filter defining fields, where, include, order, offset, and limit"
          type: "object"
          source: 'query'
          optional: true
        options:
          type: 'object'
          source: 'context'
          optional: true
      accessType: "READ"
      description: "Find all instances of the model matched by filter from the data source."
      path: "/"
      method: "get"

    findById:
      params:
        id:
          description: "Model id"
          source: "url"
          type: "any"
        filter:
          description: "Filter defining fields and include"
          type: "object"
          source: 'query'
          optional: true
        options:
          type: 'object'
          source: 'context'
          optional: true
      accessType: "READ"
      description: "Find a model instance by id from the data source."
      path: "/:id"
      method: "get"

    findOne:
      params:
        filter:
          description: "Filter defining fields, where, include, order, offset, and limit"
          type: "object"
          source: 'query'
        options:
          type: 'object'
          source: 'context'
          optional: true
      accessType: "READ"
      description: "Find first instance of the model matched by filter from the data source."
      path: "/findOne"
      method: "get"

    'prototype.updateAttributes':
      params:
        id:
          description: "Model id"
          source: "url"
          type: "any"
        data:
          description: "An object of model property name/value pairs"
          source: "body"
          type: "object"
        options:
          type: 'object'
          source: 'context'
          optional: true
      accessType: "WRITE"
      aliases: [
        "patchAttributes"
      ]
      description: "Patch attributes for a model instance and persist it into the data source."
      path: "/"
      method: "patch"

    update:
      params:
        where:
          description: "Criteria to match model instances"
          source: "query"
          type: "object"
        data:
          description: "An object of model property name/value pairs"
          source: "body"
          type: "object"
        options:
          type: 'object'
          source: 'context'
          optional: true
      accessType: "WRITE"
      aliases: [
        "update"
      ]
      description: "Update instances of the model matched by where from the data source."
      path: "/update"
      method: "post"

    updateById:
      params:
        id:
          description: "Model id"
          source: "url"
          type: "any"
        data:
          description: "Model instance data"
          source: "body"
          type: "object"
        options:
          type: 'object'
          source: 'context'
          optional: true
      accessType: "WRITE"
      description: "Replace attributes for a model instance and persist it into the data source."
      path: "/:id/patch"
      method: "post"

    #patchOrCreate:
    #  params:
    #    data:
    #      description: "Model instance data"
    #      source: "body"
    #      type: "object"
    #  accessType: "WRITE"
    #  aliases: [
    #    "upsert"
    #    "updateOrCreate"
    #  ]
    #  description: "Patch an existing model instance or insert a new one into the data source."
    #  path: "/"
    #  method: "patch"

    #replaceOrCreate:
    #  params:
    #    data:
    #      description: "Model instance data"
    #      source: "body"
    #      type: "object"
    #  accessType: "WRITE"
    #  description: "Replace an existing model instance or insert a new one into the data source."
    #  path: "/replaceOrCreate"
    #  method: "post"

    #findOrCreate:
    #  description: 'Find else create a new instance of the model and persist it into the data source'
    #  params:
    #    data:
    #      type: 'object'
    #      source: 'body'
    #  method: 'post'
    #  path: '/findOrCreate'

  @factory 'SharedModel', (PersistedModel, api, Utils, injector) ->

    class SharedModel extends PersistedModel

      @configure: (@modelName, attributes) ->
        super

        for name, config of routes
          @remoteMethod name, config

        @relations.on '*', (rel, config) =>
          routes = injector.get(config.$type + 'Routes') or
                   injector.get 'RelationRoutes'

          parent = api.section @modelName
          section = parent.section rel

          for name, route of routes.bind(config)()
            route.args = Object.keys route.params

            @remoteMethod name, route, section, (args..., cb) =>
              console.log 'shared relation', args, route.args

              data = {}

              for arg, idx in args
                data[route.args[idx]] = arg

              primaryKey = data[config.primaryKey]
              foreignKey = data[config.foreignKey]

              instance = new @
              instance.setId primaryKey

              instance[rel][name] foreignKey, cb

        @

      @remoteMethod: (name, config, section, fn) ->
        route = section or api.section @modelName

        fn ?= Utils.get @, name

        if not fn
          console.error "method #{name} not found on #{ @modelName }"
          return

        config.args ?= Utils.getArgs fn

        route[config.method] name, config, fn.bind @