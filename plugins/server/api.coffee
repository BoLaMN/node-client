'use strict'

module.exports = ->

  @factory 'api', (Section, Middleware) ->
    class Api extends Section
      constructor: ->
        super

        @use Middleware.jsonWriter()

    new Api