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

    @include './model'

    # add @model 'MyModel', (Adapter) -> for registering models

    @assembler 'model', (injector) ->
      Model = injector.get 'Model'

      (name, factory) =>
        model = Model.define name, factory

        injector.register
          name: name
          type: 'router'
          plugin: @name
          factory: model

        @

    @include './adapter'
    @include './mongo/mongo'
