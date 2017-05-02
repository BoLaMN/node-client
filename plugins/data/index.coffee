'use strict'

module.exports = (app) ->

  app

  .plugin 'Data',
    version: '0.0.1'

  .initializer ->

    @require [
      'fs'
      'path'
      'crypto'
    ]

    @include './storage'
    @include './models'
    @include './shared-model'
    @include './persisted-model'
    @include './model'
    @include './cast'
    @include './types'

    # @model 'MyModel',
    #   base: 'PersistedModel'
    #   properties:
    #     items: [ 'string' ]
    #     orderDate:
    #       type: 'date'
    #     qty:
    #       type: 'number'
    #
    # @extension 'MyModelExtension', (MyModel) ->
    #
    #   MyModel::customMethod = (params, callback) ->
    #     callback()
    #

    @assembler 'model', (injector) ->
      (name, { base, adapter, properties, relations }) =>
        injector.register
          name: name
          type: 'model'
          plugin: @name
          fn: ->
            base = base or 'Model'
            model = injector.get base

            adptr = injector.get adapter
            connector = adptr.define 'db'

            factory = model.define name, properties
            factory.adapter connector

            for as, config of relations
              config.as = as
              factory[config.type] config

            factory

        @

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

    @extension 'MyModelExtension', (MyModel) ->

      MyModel.hasMany 'Picture'

      MyModel::customMethod = (params, callback) ->
        callback()

    @include './adapter'
    @include './mongo/mongo'
