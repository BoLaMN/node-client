Entity = require './entity'
Events = require './emitter'

module.exports = ->

  @factory 'Adapter', (Storage) ->

    class Adapter extends Entity
      @extend Events::

      @adapters: new Storage

      @define: (name, settings = {}, fn = ->) ->
        if typeof settings is 'function'
          return @define name, {}, settings

        class Instance extends @

        Instance.name = name
        Instance.initialize name, settings, fn
        Instance

      @initialize: (name, @settings, fn = ->) ->
        @models = new Storage

        @adapters.$define name, @

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
