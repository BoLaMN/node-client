module.exports = (app) ->

  app

  .module 'MemoryAdapter', [ 'Adapter', 'Type' ]

  .initializer ->

    @include './orm'
    @include './collection'

    @adapter 'Memory', (MemoryORM, MemoryCollection) ->
      class Memory extends MemoryORM

        @initialize: (@name = 'memory', @settings = {}, fn = ->) ->
          super

          @connect().asCallback fn
        
        @collection: (model, data) ->
          name = @collectionName model
          
          id = @idName model
          prop = @_models[model].properties[id]

          if data 
            @data[name] = new MemoryCollection id, prop, data

          @data[name] ?= new MemoryCollection id, prop
          @data[name]

        @collectionName: (model) ->
          modelClass = @_models[model]
          modelClass.settings[@name]?.collection or model

        @connect: (callback) ->
          process.nextTick callback

        @disconnect: (callback) ->
          debug 'disconnect'

          if callback
            process.nextTick callback

        @toString: ->
          @name

