'use strict'

module.exports = (app) ->

  app

  .module 'Data', [ 'Relations', 'Server', 'MongoDBAdapter' ]

  .initializer ->

    buildModel = (name, { base, adapter, properties, relations }) =>
      base = base or 'Model'

      model = @injector.get base
      adptr = @injector.get adapter or 'MongoDB'

      connector = adptr.define 'db'

      factory = model.define name, properties
      factory.adapter connector

      for as, config of relations
        config.as = as
        factory[config.type] config

      @factory name, -> factory

      @

    @require [
      'fs'
      'path'
      'crypto'
      'glob'
    ]

    @include './module'
    @include './entity'
    @include './hooks'
    @include './attributes'
    @include './emitter'
    @include './storage'
    @include './models'
    @include './shared-model'
    @include './persisted-model'
    @include './model'
    @include './cast'
    @include './types'
    @include './object-proxy'
    @include './utils/build-options'

    @assembler 'model', ->
      (name, config) ->
        buildModel name, config

    @run (settings, glob, path) ->
      directory = settings.directorys.models
      pattern = path.join directory, '**/*.{cson,json}'
      console.log pattern
      files = glob.sync path.resolve pattern

      models = files.map (filename) ->
        config = require filename
        console.log config
        buildModel config.name, config

      models

    @model 'Picture',
      base: 'SharedModel'
      adapter: 'MongoDB'

    @model 'MyModel',
      base: 'SharedModel'
      adapter: 'MongoDB'
      properties:
        items: [ 'string' ]
        orderDate:
          type: 'date'
        qty:
          type: 'number'

    @model 'MyModel2',
      base: 'MyModel'
      adapter: 'MongoDB'

    @decorator 'MyModel', (MyModel) ->

      MyModel.hasMany 'Picture'

      MyModel::customMethod = (params, callback) ->
        callback()
