'use strict'

module.exports = ->

  @factory 'ReferencesManyInclude', (AbstractInclude) ->

    class ReferencesManyInclude extends AbstractInclude
      constructor: ->
        super

      linkFn: (target) ->
        list = objs.get target[@relation.foreignKey].toString()

        Promise.each list, @setData

      handle: ->
        @findIncludes @relation.to, filter, @relation.foreignKey, 0
          .then @targetFetchHandler
