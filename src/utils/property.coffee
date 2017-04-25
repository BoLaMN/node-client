property = (cls, key, accessor = {}) ->
  if cls[key]
    return

  if typeof accessor is 'function'
    accessor = { get: accessor }

  if accessor.value is undefined and accessor.get is undefined
    accessor.set = accessor.set or (val) ->
      @[key] = val

    accessor.get = accessor.get or ->
      @[key]

  if key.startsWith '$'
    accessor.enumerable = false

  Object.defineProperty cls, key, accessor

module.exports = property