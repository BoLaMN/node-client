'use strict'

module.exports = (app) ->

  app

  .module 'Base', [ ]

  .initializer ->

    @include './entity'
    @include './module'
    @include './storage'
    @include './emitter'
    @include './env'
    @include './utils/property'
