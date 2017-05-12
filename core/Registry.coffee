'use strict'

{ values } = require './Utils'

path = require 'path'
glob = require 'glob'

Plugin = require './Plugin'
PluginCollection = require './PluginCollection'

plugins = Symbol()

class Registry

  constructor: ->
    @[plugins] = {}

    @directories = [
      path.join process.cwd(), 'plugins'
    ]

  inspect: ->
    @list()

  list: ->
    Object.keys @[plugins]

  get: (name) ->
    @[plugins][name]

  set: (name, plugin) ->
    if not plugin instanceof Plugin
      json = JSON.stringify plugin
      throw new Error "#{json} is not a Plugin instance."

    @[plugins][name] = plugin

    plugin

  del: (name) ->
    delete @[plugins][name]

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
    Object.keys(@[plugins]).forEach (key) =>
      plugin = @[plugins][key]

      dependencies = plugin.dependencies or []

      dependencies.forEach (name) =>
        range = dependencies[name]
        dependency = @[plugins][name]

        if not dependency
          throw new Error "Dependency #{name} missing."

        dependency.dependents = dependency.dependents or {}
        dependency.dependents[plugin.name] = plugin

        plugin.metadata = plugin.metadata or {}
        plugin.metadata[name] = dependency

    @

  satisfy: (ordered, remaining) ->
    source = [].concat remaining
    target = [].concat ordered

    source.forEach (plugin, index) ->
      dependencies = values plugin.metadata

      isSatisfied = dependencies.every (dependency) ->
        target.indexOf(dependency) isnt -1

      if isSatisfied
        target.push plugin
        source.splice index, 1

    if source.length is 0 then target else @satisfy target, source

  prioritize: ->
    ordered = []
    remaining = [].concat values @[plugins]

    remaining.forEach (plugin, index) ->
      if not plugin.dependencies or plugin.dependencies.length is 0
        ordered.push plugin
        remaining.splice index, 1

    @prioritized = new PluginCollection @satisfy ordered, remaining

    @

  initialize: ->
    @prioritized.initialize()

  start: ->
    @prioritized.start()

  core: ->

    @module 'Core', []

    .initializer ->

      @require
        inflector: './Inflector'
        Utils: './Utils'

      @include './Is'
      @include './helpers/assert'

    @

  module: (name, dependencies) ->
    if dependencies
      @set name, new Plugin name, dependencies
    else
      @get name

module.exports = Registry
