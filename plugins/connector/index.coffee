module.exports = (app) ->

  app

  .module 'Connector', [ 'Base' ]

  .initializer ->

    @include './connectors'

    @assembler 'connector', ->
      (name, factory) ->
        @factory name + 'Connector', factory, 'connector'

    @factory 'Connector', (Connectors, Storage, Entity, Events) ->

      class Connector extends Entity
        @extend Events::

        @inspect: ->
          { @name
            @connected
            @connecting
            @settings } 
          
        @define: (name, settings = {}, fn = ->) ->
          if typeof settings is 'function'
            return @define name, {}, settings

          ctor = @extends name, @
          ctor.initialize settings, fn
          ctor

        @initialize: (@settings, fn = ->) ->
          @models = new Storage

          Connectors.define @name, @

        @connect: (cb = ->) ->
          process.nextTick cb

        @disconnect: (cb = ->) ->
          console.log 'disconnect'

          if cb
            process.nextTick cb

        constructor: (model) ->
          super

          @model = model
          @constructor.models.define @model.name, @model
