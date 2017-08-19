module.exports = (app) ->

  app

  .module 'TransientConnector', [ 'Connector', 'Type' ]

  .initializer ->

    @include './orm'

    @connector 'Transient', (TransientORM) ->
      class Transient extends TransientORM

        @initialize: (@settings = {}, fn = ->) ->
          super

          @connect().asCallback fn
        
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

