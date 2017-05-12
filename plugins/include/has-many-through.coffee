'use strict'

module.exports = ->

  @factory 'HasManyThroughInclude', (AbstractInclude) ->

    class HasManyThroughInclude extends AbstractInclude
      constructor: ->
        super

      handle: ->

        @findIncludes @relation.through, filter, @relation.foreignKey, 0
          .then @targetFetchHandler
