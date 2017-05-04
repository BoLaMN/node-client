'use strict'

module.exports = (app) ->

  app

  .module 'Status', [ 'Server' ]

  .initialize ->

    @router 'status', (Router) ->
      router = Router()

      router.get '/', (req, res, next) ->
        res.json status: 'OK'

      router
