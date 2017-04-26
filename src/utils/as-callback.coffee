noop = ->

asCallback = (cb = noop, options = {}) ->

  success = (data) ->
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