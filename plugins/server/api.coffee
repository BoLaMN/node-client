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

        for section of @sections
          tags.push { section }

          model = injector.get section
          attributes = model.attributes

          required = []

          for name, attribute of attributes
            if attribute.required
              required.push name

          definitions[section] =
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