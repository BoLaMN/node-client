module.exports = (app) ->

  app.module 'AccessRoles', [ 'Access' ]

  .initializer ->

    @include './$unauthenticated'
    @include './$authenticated'
    @include './$everyone'
    @include './$owner'