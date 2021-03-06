module.exports = ->

  @factory 'swagger', (injector, Types, Models, utils) ->
    { extend } = utils

    data = {}

    buildFromSchemaType = (def) ->
      if typeof def is 'string' or typeof def is 'function'
        def = type: def
      else if Array.isArray def
        def = type: def

      type = def.type or def

      if typeof type is 'string'
        kind = type
      else
        kind = typeof type

      fn = Types.get kind.toLowerCase()
      fn ?= Models.get kind

      if not fn?.swagger?.schema
        console.log 'no swagger definition found for ', kind
        return

      schema = fn.swagger.schema def

      if def.source is 'body'
        schema: schema
      else schema

    handle: (req, res) ->
      if not data.expire or data.expire >= Date.now()
        api = injector.get 'api'
        tags = []

        definitions = {}

        for own name, type of Types
          if typeof type.swagger.definition is 'function'
            definitions[name] = type.swagger.definition()

        for own name, model of Models
          tags.push { name }

          attributes = model.attributes

          properties = {}

          for own attribute, field of attributes
            schema = buildFromSchemaType field

            if schema.properties
              properties[attribute] = schema
            else
              properties[attribute] = {}
              extend properties[attribute], field, schema

            properties[attribute].id = undefined
            properties[attribute].foreignKey = undefined
            properties[attribute].defaultFn = undefined

          definitions[name] ?= {}

          definitions[name] =
            properties: properties

        data =
          expire: Date.now() + 30 * 1000
          value: api.toSwagger
            swagger: "2.0"
            info:
              version: "0.0.0"
              title: "api"
            basePath: "/api"
            paths: {}
            securityDefinitions:
              Bearer:
                type: 'apiKey'
                name: 'Authorization'
                in: 'header'
            tags: tags
            consumes: [
              "application/json"
              "application/x-www-form-urlencoded"
              "application/xml"
              "text/xml"
            ]
            produces: [
              "application/json"
              "application/xml"
              "text/xml"
              "application/javascript"
              "text/javascript"
            ]
            definitions: definitions

      res.json data.value

    buildFromSchemaType: buildFromSchemaType
