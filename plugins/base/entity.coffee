module.exports = ->

  @factory 'Entity', (Module) ->
    class Entity extends Module

      @defer: (cb) ->
        resolve = undefined
        reject = undefined

        promise = new Promise (args...) ->
          [ resolve, reject ] = args

        if cb
          promise.asCallback cb

        resolve: resolve
        reject: reject
        promise: promise

      @each: (items, iterate, callback = ->) ->
        data = []
        count = 0

        run = (item, index) ->
          iterate item, (obj) ->
            if not index
              callback obj
            else
              data[index] = obj

            count += 1

            if count is items.length
              callback data

        if Array.isArray items
          if not items.length
            return callback()
          items.forEach run
        else run items

      constructor: ->
        super

      $each: Entity.each
      $defer: Entity.defer
