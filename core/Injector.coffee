'use strict'

dependencies = Symbol()
decorators = Symbol()

class Injector

  constructor: ->
    @[dependencies] = {}
    @[decorators] = {}

    @register 'injector',
      factory:
        $get: -> @
      type: 'injector'

  register: (name, { type, factory }) ->
    if type is 'decorator'
      @[decorators][name] ?= []
      @[decorators][name].push factory
    else
      @[dependencies][name] = factory.$get
      @[dependencies][name + 'Provider'] = ->
        factory
    @

  get: (name, context) ->
    @exec @[dependencies][name], context

  parse: (factory) ->
    s = factory + ''
    match = s.match /^function\s*[a-z0-9$_]*\s*\((.*)\)/i

    if not match
      return []

    match[1]
      .trim()
      .split /\s*,\s*/g
      .filter (item) ->
        item.length > 0

  inject: (deps) ->
    deps.map (dependency) =>
      factory = @[dependencies][dependency]

      if not factory
        try
          factory = @[dependencies][dependency] = require dependency
        catch e
          throw new ReferenceError "Dependency '#{dependency}' not defined of #{ deps }"

      args = @inject @parse factory
      service = factory args...

      (@[decorators][dependency] or []).forEach (decorate) ->
        service = decorate service

      service

  exec: (factory, context) ->
    args = @inject @parse factory
    factory.apply context, args

module.exports = Injector
