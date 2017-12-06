'use strict'

module.exports = ->

  @run (api, cors) ->
    crs = cors()

    api.options 'cors', { path: '*' }, crs

    api.use 'initial', crs
