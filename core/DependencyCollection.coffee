'use strict'

injector = require './injectorInstance'

Collection = require './Collection'

class DependecyCollection extends Collection
  constructor: ->
    return super

  start: ->
    @map (dependency) ->
      injector.get dependency.name

module.exports = DependecyCollection