'use strict'

module.exports = (app) ->

  app

  .module 'Data', [ 'Relations', 'Base', 'Server', 'MongoDBAdapter', 'Access', 'Type' ]

  .initializer ->

    buildModel = (name, { base, adapter, properties, relations, acls }) =>
      base = base or 'Model'

      model = @injector.get base
      adptr = @injector.get adapter or 'MongoDB'

      connector = adptr.define 'db'

      factory = model.define name, properties, acls
      factory.adapter connector

      for as, config of relations
        config.as = as
        factory[config.type] config

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
    @include './attributes'
    @include './models'
    @include './shared-model'
    @include './persisted-model'
    @include './model'
    @include './acls'
    @include './cast'
    @include './mixins'
    @include './object-proxy'
    @include './utils/build-options'
    @include './utils/wrap'

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

    @model 'Picture',
      base: 'SharedModel'
      adapter: 'MongoDB'
      properties:
        id:
          type: 'objectid'
          id: true

    @model 'MyModel',
      base: 'SharedModel'
      adapter: 'MongoDB'
      properties:
        id:
          type: 'objectid'
          id: true
        items: [ 'string' ]
        orderDate:
          type: 'date'
        qty:
          type: 'number'

    @model 'MyModel2',
      base: 'MyModel'
      adapter: 'MongoDB'
      properties:
        id:
          type: 'objectid'
          id: true

    @extension 'MyModelExt', (MyModel) ->

      MyModel.observe 'before find', (ctx, callback) ->
        console.log arguments
        callback()

      MyModel.hasMany 'Picture'

      MyModel::customMethod = (params, callback) ->
        callback()
