wrap = require './utils/wrap'

class Hooks
  constructor: (event, fn) ->
    if event and fn
      @observe event, fn

  fire: (event, ctx = {}, fn = ->) ->
    if typeof ctx is 'function'
      return @fire event, {}, ctx

    { instance } = ctx.options?

    if event[0] isnt '$'
      event = '$' + event

    q = @defer fn

    evt = {}

    if instance
      evt = instance.$events?[event]

      instance.$property instance, event,
        value: true

    self = (err) =>
      if err
        return q.reject err

      @notify event, ctx, ->
        q.resolve ctx

    nested = (key, cb) ->
      inst = evt[key]
      inst.fire event, options, cb

    evts = Object.keys evt

    if evts?.length
      @each evts, nested, self
    else self()

    q.promise

  observe: (event, fn) ->
    if Array.isArray event
      event.forEach (e) =>
        @observe e, fn
      return @

    if event[0] isnt '$'
      event = '$' + event

    @hooks ?= {}
    @hooks[event] ?= new Hook
    @hooks[event].observe fn

    @

  notify: (event, ctx, fn = ->) ->
    if event[0] isnt '$'
      event = '$' + event

    if not @hooks?[event]
      return fn()

    @hooks[event].notify ctx, fn

class Hook
  constructor: (fn) ->
    @fns = []

    if fn
      @observe fn

  observe: (fn) ->
    if Array.isArray fn
      i = 0

      while f = fn[i++]
        @observe f

      return @

    @fns.push fn

    @

  notify: (ctx, done) ->
    i = 0
    fns = @fns

    fail = (val) ->
      throw val

    next = (err) =>
      if err
        return (done or fail)(err)

      fn = fns[i++]

      if not fn
        return done()

      wrap(fn, next).apply @, [ ctx ]

      return

    next()

    @

module.exports = Hooks