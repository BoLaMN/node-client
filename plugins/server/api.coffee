'use strict'

module.exports = ->

  @factory 'api', (Section, Middleware, injector) ->
    class Api extends Section
      constructor: ->
        super

        @use Middleware.defaults

      toSwagger: ->
        tags = []
        definitions = {}

        for name of @sections
          tags.push { name }

          model = injector.get name
          attributes = model.attributes

          required = []

          for attribute, field of attributes
            if field.required
              required.push attribute

          definitions[name] =
            properties: attributes
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