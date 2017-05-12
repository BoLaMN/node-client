'use strict'

module.exports = ->

  @factory 'EmbedOneInclude', (EmbedManyInclude) ->

    class EmbedOneInclude extends EmbedManyInclude
