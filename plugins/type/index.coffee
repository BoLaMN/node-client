'use strict'

module.exports = (app) ->

  app

  .module 'Type', [ 'Base' ]

  .initializer ->

    @include './types'
    @include './type'

    buildType = (name, factory) =>
      types = @injector.get 'Types'

      types.define name.toLowerCase(),
        @injector.exec factory

    @assembler 'type', ->
      (name, factory) ->
        buildType name, factory

    @include './default/any'
    @include './default/array'
    @include './default/boolean'
    @include './default/date'
    @include './default/float'
    @include './default/integer'
    @include './default/json'
    @include './default/number'
    @include './default/object'
    @include './default/regexp'
    @include './default/string'