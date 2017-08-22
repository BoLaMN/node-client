'use strict'

module.exports = (app) ->

  app

  .module 'Filter', []

  .initializer ->

    @include './filter'
    @include './update'
    @include './where'

    @factory 'FilterQuery', (FilterUpdate, FilterMatch, FilterWhere, debug) ->
      (obj = {}, where = {}, update = {}) ->
        query = FilterWhere where, obj.constructor.name
        match = FilterMatch obj, query

        return unless match

        FilterUpdate obj, update
