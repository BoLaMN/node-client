module.exports = (app) ->

  app

  .module 'Interpolate', [ 'Base' ]

  .initializer ->

    @include './expression'
    @include './filters'
    @include './interpolate'
    @include './to-function'
    @include './utils'
    @include './walk'
