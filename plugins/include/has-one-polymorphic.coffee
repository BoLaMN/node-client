'use strict'

module.exports = ->

  @factory 'HasOnePolymorphicInclude', (AbstractInclude) ->

    class HasOnePolymorphicInclude extends AbstractInclude
      constructor: ->
        super

      linkFn: (target) ->
        obj = objs.get target[@relation.foreignKey].toString()

        @setData obj

      handle: ->
        @findIncludes @relation.to, filter, @relation.foreignKey, 0
          .then @targetFetchHandler
