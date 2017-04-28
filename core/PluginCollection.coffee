'use strict'

Collection = require './Collection'

class PluginCollection extends Collection

  start: ->
    @forEach (plugin) ->
      plugin.start()

  initialize: ->
    @forEach (plugin) ->
      plugin.initialize()

module.exports = PluginCollection