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
    #   items: [ 'string' ]
    #   orderDate:
    #     type: 'date'
    #   qty:
    #     type: 'number'
    #
    # @extension 'MyModelExtension', (MyModel) ->
    #
    #   MyModel::customMethod = (params, callback) ->
    #     callback()
    #

    @assembler 'model', (injector) ->
      (name, config) =>
        Model = injector.get 'Model'

        model = Model.define name, config

        injector.register
          name: name
          type: 'router'
          plugin: @name
          factory: model

        @

    @include './adapter'
    @include './mongo/mongo'
