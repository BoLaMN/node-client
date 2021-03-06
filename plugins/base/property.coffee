module.exports = ->

  @decorator 'utils', (utils) ->

    utils.property = (cls, key, accessor = {}, hidden) ->
      if cls[key]
        return

      if typeof accessor is 'function'
        accessor = { get: accessor }

      if accessor.value is undefined and accessor.get is undefined
        accessor.set = accessor.set or (val) ->
          @[key] = val

        accessor.get = accessor.get or ->
          @[key]

      if key.startsWith '$' or hidden
        accessor.enumerable = false

      Object.defineProperty cls, key, accessor

    utils
