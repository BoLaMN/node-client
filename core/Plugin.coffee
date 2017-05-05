'use strict'

Provider = require './Provider'
Emitter = require './Emitter'

{ camelize } = require './Inflector'
{ zipObject } = require './Utils'

path = require 'path'
callsite = require "callsite"
injector = require './injectorInstance'

init = Symbol()

class Plugin extends Emitter

  constructor: (@name, @dependencies) ->
    @injector = injector

    super

  require: (modules) ->
    if typeof modules is 'string'
      modules = [ modules ]

    if Array.isArray modules
      modules = zipObject modules, modules, (v) ->
        camelize v, true

    Object.keys(modules).forEach (key) =>
      @factory key, -> require modules[key]
    @

  include: (filename) ->
    caller = callsite()[1]
    callerpath = caller.getFileName()
    filepath = path.join path.dirname(callerpath), filename
    require(filepath).bind(@)()
    @

  config: (configurator) ->
    @on 'config', =>
      injector.exec configurator, @
    @

  run: (configurator) ->
    @on 'run', =>
      injector.exec configurator, @
    @

  provider: (name, factory) ->
    provider = new Provider

    injector.exec factory, provider

    injector.register name,
      factory: provider
      type: 'provider'

    @

  constant: (name, factory) ->
    @factory name, factory

  value: (name, factory) ->
    @provider name, ->
      value = undefined

      @$get = ->
        if value
          return value
        value = injector.exec factory, @
        value

  service: (name, factory) ->
    @provider name, ->
      instance = undefined

      @$get = ->
        if instance
          return instance
        instance = injector.exec factory
        instance

  controller: (name, factory) ->
    @factory name, ->
      instance = new Emitter
      injector.exec factory, instance
      instance

  factory: (name, factory) ->
    @provider name, ->
      @$get = factory

  decorator: (name, factory) ->
    injector.register name,
      factory: factory
      type: 'decorator'
    @

  start: ->
    @emit 'config'
    @emit 'run'
    @

  extension: (name, mutator) ->
    @factory name, mutator
    @

  assembler: (name, factory) ->
    @constructor::[name] = factory.bind(@)()
    @

  initializer: (callback) ->
    @[init] = callback
    @

  initialize: ->
    fn = @[init]?.bind @
    fn @ if fn
    @

module.exports = Plugin
