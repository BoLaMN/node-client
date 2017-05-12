'use strict'

module.exports = ->

  @factory 'HasOneInclude', (AbstractInclude) ->

    class HasOneInclude extends AbstractInclude
      constructor: ->
        super

      linkFn: (target) ->
        obj = objs.get target[@relation.foreignKey].toString()

        Promise.each obj, @setData

      handle: ->

        @findIncludes @relation.to, filter, @relation.foreignKey, 0, options
          .then @targetFetchHandler
