'use strict'

module.exports = ->

  @factory 'TransientORM', (Connector) ->
    
    class TransientORM extends Connector
      constructor: (model) ->
        super

        @model = model

      exists: (id, callback) ->
        if not callback and 'function' == typeof id
          callback = id
          id = undefined

        @flush 'exists', false, callback

      find: (id, callback) ->
        if not callback and 'function' == typeof id
          callback = id
          id = undefined

        @flush 'find', null, callback

      all: (filter, callback) ->
        if not callback and 'function' == typeof filter
          callback = filter
          filter = undefined

        @flush 'all', [], callback

      count: (where, callback) ->
        if not callback and 'function' == typeof where
          callback = where
          where = undefined

        @flush 'count', 0, callback

      create: (data, callback) ->
        @flush 'create', id, callback

      save: (data, callback) ->
        @flush 'save', data, callback

      update: TransientORM::updateAll

      updateAll: (where, data, cb) ->
        count = 0

        @flush 'update', { count }, cb

      updateAttributes: (id, data, cb) ->
        if !id
          err = new Error 'You must provide an id when updating attributes!'
        
          if cb
            return cb err
          else
            throw err
        
        @setIdValue data, id
        @save data, cb

      destroy: (id, callback) ->
        @flush 'destroy', null, callback

      destroyAll: (where, callback) ->
        if not callback and 'function' == typeof where
          callback = where
          where = undefined

        @flush 'destroyAll', null, callback

      flush: (action, result, callback = ->) ->
        process.nextTick ->
          callback null, result

      transaction: ->
        new Transient this

      exec: (callback) ->
        @onTransactionExec()

        setTimeout callback, 50
