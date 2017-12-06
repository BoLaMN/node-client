'use strict'

module.exports = ->
  
  @factory 'MongoQuery', (MongoQueryAggregate, FilterWhere) ->

    class MongoQuery
      constructor: (filter, @model, options = {}) ->
        @filter =
          include: null
          aggregate: []
          fields: {}
          opts: {}
          options: options
          where: {}

        for own key, value of filter
          if typeof @[key] is 'function'
            @[key] value
          else
            console.warn 'query filter ' + key + ' not found, value: '

      where: (conditions) ->
        @filter.where = FilterWhere conditions, @model

        this

      ###*
      # set aggregate query
      #
      # @param {String} key
      # @api public
      ###

      aggregate: (conditions) ->
        { query } = new MongoQueryAggregate conditions
        @filter.aggregate = query

        this

      ###*
      # Handle iterating over include/exclude methods
      #
      # @param {String} key
      # @param {Mixed} value
      # @api public
      ###

      fields: (fields, value = 1) ->
        if Array.isArray fields
          for key in fields 
            @fields key

        if typeof fields is 'object'
          for own key, value of fields
            @fields key, value

        if typeof fields is 'string'
          @filter.fields[fields] = value

        this

      ###*
      # Exclude fields from result
      #
      # @param {String} key
      # @api public
      ###

      exclude: (fields) ->
        @fields fields, 0

        this

      ###*
      # Set query limit
      #
      # @param {Number} limit - limit number
      # @api public
      ###

      limit: (limit) ->
        @filter.options.limit = limit

        this

      include: (includes) ->
        @filter.include = includes

        this

      ###*
      # Set query skip
      #
      # @param {Number} skip - skip number
      # @api public
      ###

      skip: (skip) ->
        @filter.options.skip = skip

        this

      ###*
      # Alias for skip
      #
      # @param {String} offset
      # @api public
      ###

      offset: (offset) ->
        @skip offset

      ###*
      # Sort query results
      #
      # @param {Object} sort - sort params
      # @api public
      ###

      order: (sorts, value) ->
        if Array.isArray sorts
          for sort in sorts
            @order.apply this, sort.split ' '

        if typeof value is 'string'
          matches = sorts.match /([\w\d]+) (A|DE)SC/gi

          if matches
            return @order matches

          if sorts is @model.primaryKey
            sorts = '_id'

          @filter.opts.sort ?= {}
          @filter.opts.sort[sorts] = if value is 'DE' then -1 else 1
        else
          @filter.opts.sort = _id: 1

        this

