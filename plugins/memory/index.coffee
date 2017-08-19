module.exports = (app) ->

  app

  .module 'MemoryConnector', [ 'Connector', 'Type' ]

  .initializer ->

    @include './orm'
    @include './collection'

    @connector 'Memory', (MemoryORM, MemoryCollection) ->
      class Memory extends MemoryORM

        @initialize: (@settings = {}, fn = ->) ->
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

        @connect: ->
          @connecting = true
          @connected = true

          Promise.resolve()

        @disconnect: (callback) ->
          debug 'disconnect'

          if callback
            process.nextTick callback

        @toString: ->
          @name

