'use strict'

{ values } = require './Utils'

path = require 'path'
glob = require 'glob'

Plugin = require './Plugin'
PluginCollection = require './PluginCollection'

{ glob2re } = require './Utils' 

plugins = Symbol()
dir = path.join __dirname, '..'

class Registry

  constructor: (options) ->
    @[plugins] = {}

    @files = []
    @directories = []

    for key, value of options
      @[key] = value

    if @directories.indexOf(dir) is -1
      @directories.unshift dir

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
    files = @directories.reduce (results, directory) ->
      pattern = path.join directory, 'plugins', '**/index.{coffee,js}'
      files = glob.sync path.resolve pattern
      results.concat files
    , []

    Array::push.apply @files, files

    @

  modules: ->

    find = (d) ->
      if not d
        d = path.dirname module.filename or module.id

      if d is '/'
        throw new Error 'Could not find package.json up from ' + (module.filename or module.id)
      else if not d or d is '.'
        throw new Error 'Cannot find package.json from unspecified directory'

      try
        contents = require d + '/package.json'
      catch error

      if contents
        return contents

      find path.dirname d

    config = find dir

    scope = [
      'dependencies'
      'devDependencies'
      'peerDependencies'
      'optionalDependencies'
    ]
    
    re = glob2re 'node-*'
   
    modules = scope.reduce (result, prop) ->
      deps = Object.keys config[prop] or {}
      result.concat deps.filter (dep) ->
        re.test dep
    , []

    Array::push.apply @files, modules

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
    @
    
  assemble: ->
    @prioritized.assemble()
    @

  start: ->
    @prioritized.start()
    @

  core: ->

    @module 'Core', []

    .initializer ->

      @require
        inflector: './Inflector'
        util: 'util'
        utils: './Utils'

      @include './Env'
      @include './Is'
      @include './Parsers'

      @config (parsersProvider, csonParser, coffeeScript) ->

        parsersProvider

          .register 'js', (mod, content, file) ->
            mod._compile content, file 

          .register 'json', (mod, content) ->
            mod.exports = JSON.parse content

          .register 'coffee', (mod, content, file) ->
            js = coffeeScript.compile content, false, true
            mod._compile js, file 

          .register 'cson', (mod, content) -> 
            mod.exports = csonParser.parse content

        return 
      
      @include './KeyArray'
      @include './helpers/assert'

    @

  module: (name, dependencies) ->
    if dependencies
      @set name, new Plugin name, dependencies, @
    else
      @get name

  assembler: (name, factory) ->
    Object.defineProperty Plugin::, name, 
      value: factory

    @

module.exports = Registry
