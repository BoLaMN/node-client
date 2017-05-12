'use strict'

module.exports = (app) ->

  app

  .module 'Include', [ ]

  .initializer ->

    @include './include'

    @include './abstract'
    @include './embed-many'
    @include './embed-one'
    @include './has-many-through'
    @include './has-many'
    @include './has-one-polymorphic'
    @include './has-one'
    @include './references-many'