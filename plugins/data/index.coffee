'use strict'

module.exports = (app) ->

  app

  .module 'Data', [ 'Relations', 'Base', 'Server', 'MongoDBAdapter', 'Access', 'Type', 'Validation' ]

  .initializer ->

    buildModel = (name, config) =>
      model = @injector.get config.base or 'Model'
      adptr = @injector.get config.adapter or 'MongoDB'

      connector = adptr.define 'db'

      factory = model.define name, config
      factory.adapter connector

      service = ->
        factory

      @factory name, service, 'model'

      @

    @require [
      'fs'
      'path'
      'crypto'
      'glob'
    ]

    @include './hooks'
    @include './attribute'
    @include './attributes'
    @include './models'
    @include './shared-model'
    @include './persisted-model'
    @include './model'
    @include './acls'
    @include './cast'
    @include './context'
    @include './include'
    @include './mixins'
    @include './object-proxy'
    @include './utils/build-options'
    @include './utils/wrap'
    @include './utils/merge-query'

    @assembler 'model', ->
      (name, config) ->
        buildModel name, config

    @run (settings, glob, path) ->
      directory = settings.directorys.models
      pattern = path.join directory, '**/*.{cson,json}'

      files = glob.sync path.resolve pattern

      models = files.map (filename) ->
        config = require filename
        buildModel config.name, config

      models

    @model 'TransientModel', {}
