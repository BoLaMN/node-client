'use strict'

module.exports = ->

  @factory 'HasManyInclude', (AbstractInclude) ->

    class HasManyInclude extends AbstractInclude
      constructor: ->
        super

      linkFn: (target) ->
        targetIds = [].concat target[@relation.foreignKey]

        Promise.each targetIds, @setData

      handle: ->
        if @objs.length is 0
          return Promise.each @objs, @setData

        @findIncludes @relation.to, filter, @relation.foreignKey, 0
          .then @targetFetchHandler
