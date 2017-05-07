module.exports = (app) ->

  app

  .module 'Adapter', []

  .initializer ->

    @include './adapters'

    @factory 'Adapter', (Adapters, Storage, Entity, Events) ->

      class Adapter extends Entity
        @extend Events::

        @define: (name, settings = {}, fn = ->) ->
          if typeof settings is 'function'
            return @define name, {}, settings

          class Instance extends @

          Instance.name = name
          Instance.initialize name, settings, fn
          Instance

        @initialize: (name, @settings, fn = ->) ->
          @models = new Storage

          Adapters.$define name, @

        @connect: (cb = ->) ->
          process.nextTick cb

        @disconnect: (cb = ->) ->
          console.log 'disconnect'

          if cb
            process.nextTick cb

        constructor: (model) ->
          super

          @model = model
          @constructor.models.$define @model.modelName, @model
