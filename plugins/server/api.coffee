'use strict'

module.exports = ->

  @factory 'api', (Section, Middleware, injector, Swagger, Utils, Models, Types) ->
    { extend } = Utils

    class Api extends Section
      constructor: ->
        super

        @use Middleware.defaults

        @error Middleware.errorHandler

        fn = (cb) ->
          cb null, @toSwagger()

        @get 'swagger', { args: [ 'cb' ], path: '/swagger.json' }, fn.bind @

      toSwagger: ->
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
            schema = Swagger.buildFromSchemaType field

            if schema.properties
              properties[attribute] = schema
            else
              properties[attribute] = {}
              extend properties[attribute], field, schema

            delete properties[attribute].id
            delete properties[attribute].foreignKey
            delete properties[attribute].defaultFn

          definitions[name] =
            properties: properties

        super
          swagger: "2.0"
          info:
            version: "0.0.0"
            title: "api"
          basePath: "/api"
          paths: {}
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

    new Api