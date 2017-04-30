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
      (name, { base, properties, relations }) =>
        injector.register
          name: name
          type: 'model'
          plugin: @name
          fn: ->
            base = base or 'Model'

            model = injector.get base
            factory = model.define name, properties

            for as, config of relations
              config.as = as
              factory[config.type] config

            factory

        @

    @model 'MyModel',
      base: 'SharedModel'
      properties:
        items: [ 'string' ]
        orderDate:
          type: 'date'
        qty:
          type: 'number'

    @extension 'MyModelExtension', (MyModel) ->

      MyModel::customMethod = (params, callback) ->
        callback()

    @include './adapter'
    @include './mongo/mongo'
