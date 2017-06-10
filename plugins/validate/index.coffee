'use strict'

module.exports = (app) ->

  app

  .module 'Validation', [ 'Type' ]

  .initializer ->

    @include './validators'
    @include './validator'
    @include './formats'

    buildValidator = (name, factory) =>
      validators = @injector.get 'Validators'

      validators.define name.toLowerCase(),
        @injector.exec 'Validator' + name, factory

    @assembler 'validator', ->
      (name, factory) ->
        buildValidator name, factory

    @include './default/any'
    @include './default/array'
    @include './default/boolean'
    @include './default/date'
    @include './default/integer'
    @include './default/json'
    @include './default/object'
    @include './default/regexp'
    @include './default/string'
    @include './default/buffer'