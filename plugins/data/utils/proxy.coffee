isObject = (obj) ->
  obj != null and Object::toString.call(obj) is '[object Object]'

class ObserverProxy

  constructor: (@self, @path = '', @notifier = @self) ->
    return new Proxy @self, @

  canModify: (attributes, name) ->
    if Array.isArray @self
      return true

    descriptor = Object.getOwnPropertyDescriptor attributes, name

    if descriptor
      return true

    true

  defineProperty: (attributes, name, descriptor) ->
    if 'value' of descriptor
      @set attributes, name, descriptor.value

      delete descriptor.value

    Object.defineProperty attributes, name, descriptor

    true

  changed: (name, oldVal, newVal) ->
    path = @append name
    type = '$set'

    if newVal is undefined
      type = '$unset'

    @self.emit type, path, newVal

    return

  compare: (a, b) ->
    if a is b
      return true

    if Array.isArray(a) and Array.isArray(b)

      if a.length isnt b.length
        return false

      i = 0

      while i < a.length
        if not @compare a[i], b[i]
          return false

        i++

      return true

    if isObject(a) and isObject(b)
      ka = Object.keys a
      kb = Object.keys b

      if ka.length isnt kb.length
        return false

      i = 0

      while i < ka.length
        if kb.indexOf(ka[i]) is -1
          return false

        if not @compare a[ka[i]], b[ka[i]]
          return false

        i++

      return true

    false

  append: (name) ->
    [ @path, (name + '') ]
      .filter (v) -> v
      .join '.'

  set: (attributes, name, value) ->
    if not @canModify attributes, name
      return false

    oldVal = attributes[name]

    if @compare oldVal, value
      return true

    if Array.isArray value
      attributes[name] = value
    else
      cast = @self.constructor.attributes[name]
      coerced = cast?.apply?(name, value, @self)

      if cast?.foreignKey
        key = @append(name).replace /\.\d+/g, ''

        if oldVal
          @notifier.emit '$deindex', key, oldVal, @self

        @notifier.emit '$index', key, value, @self

      if coerced isnt undefined
        value = coerced

        if isObject value and not value?.constructor?.modelName
          proxy = new ObserverProxy {}, @append(name), @notifier

          for own name of value
            descriptor = Object.getOwnPropertyDescriptor value, name

            Object.defineProperty proxy, name, descriptor

          value = proxy

      attributes[name] = value

    if Array.isArray(@self) and name is 'length'
      return true

    if name[0] is '$' or value?.constructor?.modelName
      return true

    @changed name, oldVal, value

    true

  deleteProperty: (attributes, name) ->
    if not @canModify attributes, name
      return false

    oldVal = attributes[name]

    try
      delete attributes[name]
    catch e
      return false

    @changed name, oldVal

    true

module.exports = ObserverProxy