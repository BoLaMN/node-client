'use strict'

{ values } = require './Utils'

path = require 'path'
glob = require 'glob'

Plugin = require './Plugin'
PluginCollection = require './PluginCollection'

storage = Symbol()

class Registry

  constructor: ->
    @[storage] = {}

    @directories = [
      path.join process.cwd(), 'plugins'
    ]

  get: (name) ->
    @[storage][name]

  set: (name, plugin) ->
    if not plugin instanceof Plugin
      json = JSON.stringify plugin
      throw new Error "#{json} is not a Plugin instance."

    @[storage][name] = plugin

    plugin

  del: (name) ->
    delete @[storage][name]

  glob: ->
    @files = @directories.reduce (results, directory) ->
      pattern = path.join directory, '**/index.{coffee,js}'
      files = glob.sync path.resolve pattern
      results.concat files
    , []
    @

  require: ->
    @files.forEach (filename) =>
      require(filename) @
    @

  resolve: ->
    Object.keys(@[storage]).forEach (key) =>
      plugin = @[storage][key]

      metadata = plugin.metadata
      dependencies = metadata.dependencies or {}

      Object.keys(dependencies).forEach (name) =>
        range = dependencies[name]
        dependency = @[storage][name]

        if not dependency
          throw new Error "Dependency #{name} missing."

        dependency.dependents = dependency.dependents or {}
        dependency.dependents[plugin.name] = plugin

        plugin.dependencies = plugin.dependencies or {}
        plugin.dependencies[name] = dependency

    @

  satisfy: (ordered, remaining) ->
    source = [].concat remaining
    target = [].concat ordered

    source.forEach (plugin, index) ->
      dependencies = values plugin.dependencies

      isSatisfied = dependencies.every (dependency) ->
        target.indexOf(dependency) isnt -1

      if isSatisfied
        target.push plugin
        source.splice index, 1

    if source.length is 0 then target else @satisfy target, source

  prioritize: ->
    ordered = []
    remaining = [].concat values @[storage]

    remaining.forEach (plugin, index) ->
      if not plugin.dependencies or Object.keys(plugin.dependencies).length is 0
        ordered.push plugin
        remaining.splice index, 1

    @prioritized = new PluginCollection @satisfy ordered, remaining

    @

  initialize: ->
    @prioritized.initialize()

  start: ->
    @prioritized.start()

  plugin: (name, metadata) ->
    if metadata
      @set name, new Plugin name, metadata
    else
      @get name

module.exports = Registry
