'use strict'

dependencies = Symbol()
decorators = Symbol()
modules = Symbol()

class Injector

  constructor: ->
    @[dependencies] = {}
    @[decorators] = {}
    @[modules] = {}

    @register 'injector',
      factory:
        $get: => @
      type: 'injector'

  register: (name, { type, factory }) ->
    if type is 'decorator'
      @[decorators][name] ?= []
      @[decorators][name].push factory
    else

      if @[dependencies][name]
        return

      @[dependencies][name] = factory.$get

      @[modules][type] ?= []
      @[modules][type].push name

    if type is 'provider'
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
        module = require name
      catch e
        throw new ReferenceError "Dependency '#{name}' not defined"

      if module
        factory = @[dependencies][name] = -> module

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

  listByType: ->
    @[modules]

  list: ->
    Object.keys @[dependencies]

  inspect: ->
    @list()

module.exports = Injector
