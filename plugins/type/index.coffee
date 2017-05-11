'use strict'

module.exports = (app) ->

  app

  .module 'Type', [ 'Base' ]

  .initializer ->

    @include './types'

    buildType = (name, factory) =>
      types = @injector.get 'Types'

      types.define name.toLowerCase(),
        @injector.exec factory

    @assembler 'type', ->
      (name, factory) ->
        buildType name, factory
