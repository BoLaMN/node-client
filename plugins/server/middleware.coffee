'use strict'

module.exports = ->

  @run (api, cors) ->

    api.use 'initial', cors()
