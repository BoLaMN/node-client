'use strict'

module.exports = (app) ->

  app

  .module 'Boot', [ 'Data' ]

  .initializer ->

    @include './boot'
    @include './datasources'
    @include './mixins'
    @include './components'
    @include './models'
    @include './config'
    @include './middleware'
    @include './connectors'

