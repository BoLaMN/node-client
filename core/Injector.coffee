'use strict'

Dependency = require './Dependency'

storage = Symbol()

class Injector

  constructor: ->
    @[storage] =
      injector:
        name: 'injector'
        value: @

  register: (descriptor) ->
    dependency = new Dependency descriptor
    @[storage][dependency.name] = dependency

  get: (name) ->
    descriptor = @[storage][name]

    if !descriptor
      throw new Error('Unknown dependency \'#{name}\'')

    value = descriptor.value

    if !value
      values = []

      fn = descriptor.fn

      descriptor.dependencies.forEach (dependency) =>
        if dependency
          values.push @get(dependency)
        return

      value = descriptor.value = fn.apply(null, values)

    value

  invoke: (name) ->
    dependency = @[storage][name]

    if not dependency
      return

    { dependencies, fn } = dependency

    values = []

    dependencies.forEach (item) =>
      values.push @get item

    fn.apply null, values

module.exports = Injector
