module.exports = (app) ->

  app

  .module 'Adapter', [ 'Base' ]

  .initializer ->

    @include './adapters'

    @assembler 'adapter', ->
      (name, factory) ->
        @factory name, factory, 'adapter'

    @factory 'Adapter', (Adapters, Storage, Entity, Events) ->

      class Adapter extends Entity
        @extend Events::

        @inspect: ->
          @name 
          
        @define: (name, settings = {}, fn = ->) ->
          if typeof settings is 'function'
            return @define name, {}, settings

          ctor = @extends name, @
          ctor.initialize settings, fn
          ctor

        @initialize: (@settings, fn = ->) ->
          @models = new Storage

          Adapters.define @name, @

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
