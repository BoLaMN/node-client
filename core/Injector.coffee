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
    factory = @require name
    args = @inject @parse factory
    service = @decorate name, factory args...
    factory.apply context, args

  decorate: (name, service) ->
    (@[decorators][name] or []).forEach (decorate) ->
      service = decorate service
    service

  require: (name) ->
    factory = @[dependencies][name]

    if not factory
      try
        factory = @[dependencies][name] = require name
      catch e
        throw new ReferenceError "Dependency '#{name}' not defined"

    factory

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
    deps.map (name) =>
      factory = @require name
      args = @inject @parse factory
      @decorate name, factory args...

  exec: (factory, context) ->
    args = @inject @parse factory
    factory.apply context, args

module.exports = Injector
