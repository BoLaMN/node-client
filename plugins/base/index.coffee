'use strict'

module.exports = (app) ->

  app

  .module 'Base', [ ]

  .initializer ->

    @include './entity'
    @include './module'
    @include './storage'
    @include './emitter'
    @include './property'

    @factory 'debug', (env, inspect) ->
      debug = require 'debug'

      (name) -> 
        if not env.DEBUG 
          return -> 

        debug name

    @factory 'inspect', (util, env) ->
      { inspect } = util 

      (args...) -> 
        if not env.DEBUG 
          return args

        inspect args... 
