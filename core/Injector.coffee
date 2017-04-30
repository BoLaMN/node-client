'use strict'

Dependency = require './Dependency'

modules = Symbol()

class Injector

  constructor: ->
    @[modules] = {}

    @register
      name: 'injector'
      value: @

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

module.exports = Injector
