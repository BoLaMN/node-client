'use strict'

module.exports = ->

  @factory 'api', (Section, Middleware, injector, Swagger, Utils) ->
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

        definitions =
          'x-any': properties: {}

        for name of @sections
          tags.push { name }

          model = injector.get name
          attributes = model.attributes

          required = []
          properties = {}

          for own attribute, field of attributes
            properties[attribute] = {}
            schema = Swagger.buildFromSchemaType field
            extend properties[attribute], field, schema

            if field.required
              required.push attribute

          definitions[name] =
            properties: properties
            required: required
            additionalProperties: false

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