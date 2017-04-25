isObject = (obj) ->
  obj != null and Object::toString.call(obj) is '[object Object]'

noop = (v) -> v

asCallback = (fn = noop, cb, options = {}) ->
  if typeof fn is 'function' and not cb
    return @asCallback noop, fn

  if isObject fn
    return @asCallback noop, noop, fn

  if isObject cb
    return @asCallback fn, noop, cb

  fn = fn or noop

  success = (data) ->
    data = fn data

    if options.spread and Array.isArray data
      cb.apply null, [ null ].concat data
    else
      cb null, data
    data

  error = (err) ->
    cb err
    err

  @then success, error

  @

tap = (handler) ->
  promise = @constructor or Promise

  @then (v) ->
    promise.resolve handler(v)
    v

Promise::asCallback ?= asCallback
Promise::tap ?= tap

module.exports = asCallback