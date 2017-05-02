class Utils

  @values: (object = {}) ->
    Object.keys(object).map (key) ->
      object[key]

  @zipObject: (a1, a2) ->
    obj = {}
    for key, idx in a1
      obj[key] = a2[idx]
    obj

  @getArgs: (fn) ->
    fn
      .toString()
      .match(/function\s.*?\(([^)]*)\)/)[1]
    .split ','
    .map (arg) -> arg.replace(/\/\*.*\*\//, '').trim()
    .filter (arg) -> arg

  @getDeepProperty: (obj, path) ->
    if !obj or !path
      return obj

    current = obj
    split = path.split '.'

    if not split.length
      return current

    i = 0

    while i < split.length
      if current[split[i]] is undefined
        current = ''
        break
      current = current[split[i]]
      i++

    current

  @setDeepProperty: (target, chain, value) ->
    key = chain.shift()

    if chain.length is 0 and value isnt undefined
      target[key] = value
    else if chain.length != 0
      if !target[key]
        target[key] = {}

      Utils.setDeepProperty target[key], chain, value

    return

  @flatten: (arr, ret) ->
    if !Array.isArray(arr)
      return [ arr ]

    ret = ret or []
    i = 0

    while i < arr.length
      if Array.isArray(arr[i])
        exports.flatten arr[i], ret
      else
        ret.push arr[i]

      ++i

    ret

module.exports = Utils