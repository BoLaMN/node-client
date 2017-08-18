'use strict'

module.exports = (app) ->

  app

  .module 'Data', [ 'Relations', 'Base', 'Server', 'MongoDBAdapter', 'Access', 'Type', 'Validation' ]

  .initializer ->

    @require [
      'fs'
      'path'
      'crypto'
      'glob'
    ]

    @include './base'
    @include './hooks'
    @include './attribute'
    @include './attributes'
    @include './models'
    @include './datasources'
    @include './shared-model'
    @include './persisted-model'
    @include './model'
    @include './acls'
    @include './cast'
    @include './context'
    @include './include'
    @include './mixin'
    @include './mixins'
    @include './object-proxy'
    @include './utils/build-options'
    @include './utils/wrap'
    @include './utils/merge-query'

    @assembler 'model', ->
      (name, definition, config = {}, fn) =>
        Model = @injector.get definition.base or 'Model'
        Adapters = @injector.get 'Adapters'

        factory = Model.define name, definition
        
        if config.dataSource
          Adapters.get config.dataSource, (connector) ->
            factory.adapter connector

        mixins = Object.keys definition.mixins or {} 
        mixins.forEach (mixin) ->
          factory.mixin mixin, definition.mixins[mixin]

        if fn
          fn factory
        
        service = ->
          factory

        @factory name, service, 'model'

        @

    @model 'TransientModel', { }
