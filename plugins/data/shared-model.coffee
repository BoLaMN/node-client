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

  @factory 'SharedModel', (PersistedModel, api, Utils) ->

    class SharedModel extends PersistedModel

      @configure: (@modelName, attributes) ->
        super

        for name, config of routes
          @remoteMethod name, config

        @

      @remoteMethod: (name, { method, path, params, description, accessType }) ->
        route = api.section @modelName

        fn = Utils.get @, name

        if not fn
          [ prot, rel, fn ] = name.split '.'
          fn = Utils.get @relations, [ rel, prot, fn ].join '.'

        if not fn
          console.error "method #{name} not found on #{ @modelName }"
          return

        args = Utils.getArgs fn

        route[method] name, path, { params, description, accessType, args }, fn.bind @