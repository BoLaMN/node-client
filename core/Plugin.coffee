'use strict'

{ zipObject } = require './Utils'

path = require 'path'
callsite = require "callsite"
injector = require './injectorInstance'

storage = Symbol()

class Plugin

  constructor: (@name, @metadata) ->

  require: (modules) ->
    if typeof modules is 'string'
      modules = [ modules ]

    if Array.isArray modules
      modules = zipObject modules, modules

    Object.keys(modules).forEach (key) =>
      @module key, -> require modules[key]
    @

  include: (filename) ->
    caller = callsite()[1]
    callerpath = caller.getFileName()
    filepath = path.join path.dirname(callerpath), filename
    require(filepath).bind(@)()
    @

  module: (name, factory) ->
    injector.register
      name: name
      type: 'module'
      plugin: @name
      fn: factory

  factory: (name, factory) ->
    injector.register
      name: name
      type: 'factory'
      plugin: @name
      fn: factory
    @

  adapter: (name, factory) ->
    injector.register
      name: name
      type: 'adapter'
      plugin: @name
      fn: factory
    @

  alias: (alias, name) ->
    injector.register
      name: alias
      type: 'alias'
      plugin: @name
      fn: ->
        injector.get name
    @

  extension: (name, mutator) ->
    injector.register
      name: name
      type: 'extension'
      plugin: @name
      fn: mutator
    @

  assembler: (name, factory) ->
    @constructor[name] = factory injector, @
    @

  initializer: (callback) ->
    @[storage] = callback
    @

  initialize: ->
    fn = @[storage]?.bind @
    fn @ if fn
    @

  starter: (callback) ->
    injector.register
      name: "#{@name}:starter"
      type: 'starter'
      plugin: @name
      fn: callback
    @

  start: ->
    injector.invoke "#{@name}:starter"
    @

  stopper: (callback) ->
    injector.register
      name: "#{@name}:stopper"
      type: 'stopper'
      plugin: @name
      fn: callback
    @

  stop: ->
    injector.invoke "#{@name}:stopper"
    @

module.exports = Plugin
