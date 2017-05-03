'use strict'

module.exports = (app) ->

  app

  .plugin 'Status',
    version: '0.0.1'
    dependencies: [ 'Server' ]

  .initialize ->

    @router 'status', (Router) ->
      router = Router()

      router.get '/', (req, res, next) ->
        res.json status: 'OK'

      router
