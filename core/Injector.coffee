'use strict'

Dependency = require './Dependency'
DependencyCollection = require './DependencyCollection'

modules = Symbol()
config = Symbol()
run = Symbol()

class Injector

  constructor: ->
    @[modules] = {}

    @[config] = []
    @[run] = []

    @register
      name: 'injector'
      value: @

  config: (descriptor) ->
    dependency = new Dependency descriptor
    @[config].push dependency

  run: (descriptor) ->
    dependency = new Dependency descriptor
    @[run].push dependency

  register: (descriptor) ->
    dependency = new Dependency descriptor
    @[modules][dependency.name] = dependency

  inspect: ->
    @list()

  list: ->
    Object.keys @[modules]

  get: (name) ->
    descriptor = @[modules][name]

    if !descriptor
      throw new Error "Unknown dependency '#{name}'"

    value = descriptor.value

    if not value
      values = []

      fn = descriptor.fn

      descriptor.dependencies.forEach (dependency) =>
        values.push @get dependency if dependency

      value = descriptor.value = fn.apply(null, values)

    value

  invoke: (name) ->
    dependency = @[modules][name]

    if not dependency
      return

    { dependencies, fn } = dependency

    values = []

    dependencies.forEach (item) =>
      values.push @get item

    fn.apply null, values

  filter: (predicate) ->
    collection = new DependencyCollection @[modules]
    collection = collection.concat @[config], @[run]
    collection.filter predicate

module.exports = Injector
