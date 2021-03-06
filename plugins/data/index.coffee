'use strict'

module.exports = (app) ->

  app

  .module 'Data', [ 'Relations', 'Base', 'Server', 'MongoDBConnector', 'Access', 'Type', 'Validation' ]

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
        Connectors = @injector.get 'Connectors'

        factory = Model.define name, definition
        
        if config.dataSource
          Connectors.get config.dataSource, (connector) ->
            factory.connector connector

        mixins = Object.keys definition.mixins or {} 
        
        mixins.forEach (mixin) ->
          factory.mixin mixin, definition.mixins[mixin]

        args = @injector.inject @injector.parse(fn), name, false

        if fn
          fn.apply factory, args
        
        service = ->
          factory

        @factory name, service, 'model'

        @

    @model 'TransientModel', { }
