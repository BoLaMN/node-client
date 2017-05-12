'use strict'

module.exports = ->

  @factory 'EmbedManyInclude', (AbstractInclude) ->

    class EmbedManyInclude extends AbstractInclude
      constructor: ->
        super

      handle: ->
        Promise.each objs, @setData
