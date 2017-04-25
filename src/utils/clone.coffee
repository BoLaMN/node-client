
clone = (obj) ->

  switch Object::toString.call(obj)
    when '[object Array]'
      copy = new Array(obj.length)

      i = 0
      l = obj.length

      while i < l
        copy[i] = clone(obj[i])
        i++

      return copy
    when '[object Object]'
      copy = {}

      for key of obj
        if Object::hasOwnProperty.call(obj, key)
          copy[key] = clone(obj[key])

      return copy
    when '[object RegExp]'
      flags = ''
      flags += if obj.multiline then 'm' else ''
      flags += if obj.global then 'g' else ''
      flags += if obj.ignoreCase then 'i' else ''

      return new RegExp(obj.source, flags)
    when '[object Date]'
      return new Date(obj.getTime())
    else
      return obj

  return

module.exports = clone