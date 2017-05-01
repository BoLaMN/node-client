'use strict'

Collection = require './Collection'

class DependecyCollection extends Collection
  constructor: ->
    return super

  start: ->
    @map (dependency) ->
      injector = require './injectorInstance' # ??
      injector.get dependency.name

module.exports = DependecyCollection