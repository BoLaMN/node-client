'use strict'

module.exports = (app) ->

  app

  .module 'MongoQuery', []

  .initializer ->

    @include './aggregate'

    @factory 'MongoQuery', (MongoQueryAggregate, isObject, isPlainObject) ->

      class MongoQuery
        constructor: (filter, @model, options = {}) ->
          @filter =
            include: null
            aggregate: []
            fields: {}
            options: options
            where: {}

          for own key, value of filter
            if typeof @[key] is 'function'
              @[key] value
            else
              console.warn 'query filter ' + key + ' not found, value: '
        ###*
        # set where query
        #
        # @param {String} key
        # @api public
        ###

        getPropertyDefinition: (prop) ->
          current = @model
          split = prop.replace(/\.\d+/g, '').split '.'

          if split.length is 1
            return current.attributes[split[0]]

          i = 0

          while i < split.length
            current = current.relations[split[i]]?.to or current.attributes[split[i]]
            i++

          current

        where: (conditions) ->
          query = {}

          if conditions is null or not isObject conditions
            return conditions

          idName = @model.primaryKey

          Object.keys(conditions).forEach (k) =>
            cond = conditions[k]

            if k in [ 'and', 'or', 'nor' ]
              if Array.isArray cond
                cond = cond.map (c) => @where c

              query['$' + k] = cond
              delete query[k]

              return

            attr = @getPropertyDefinition k

            parse = (c) ->
              c.reduce (prev, x) ->
                b = attr.apply x
                prev.push b if b?
                prev
              , []

            if attr.id
              k = '_id'

            query[k] ?= {}

            if cond is null
              query[k].$type = 10
            else if isPlainObject cond
              options = cond.options
              specs = Object.keys cond

              specs.forEach (spec) ->
                c = cond[spec]

                if spec is 'between'
                  query[k].$gte = c[0]
                  query[k].$lte = c[1]
                else if spec is 'inq' and Array.isArray c
                  query[k].$in = parse c
                else if spec is 'nin' and Array.isArray c
                  query[k].$nin = parse c
                else if spec is 'like'
                  query[k].$regex = new RegExp c, options
                else if spec is 'nlike'
                  query[k].$not = new RegExp c, options
                else if spec is 'neq'
                  query[k].$ne = c
                else if spec is 'regexp'
                  if c.global
                    console.warn 'MongoDB regex syntax does not respect the `g` flag'
                  query[k].$regex = c
                else

                  if spec[0] isnt '$'
                    spec = '$' + spec

                  query[k][spec] = c
            else
              if attr
                cond = attr.apply cond

              query[k] = cond

          @filter.where = query

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
            fields.forEach (key) =>
              @fields key

          if typeof fields is 'object'
            keys = Object.keys fields
            keys.forEach (key) =>
              @fields key, fields[key]

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
        # Search using text index
        #
        # @param {String} text
        # @api public
        ###

        search: (text) ->
          @where '$text': '$search': text

          this

        ###*
        # Sort query results
        #
        # @param {Object} sort - sort params
        # @api public
        ###

        sort: (sorts, value) ->
          if Array.isArray sorts
            sorts.forEach (sort) =>
              @sort.apply this, sort.split ' '

          if typeof value is 'string'
            matches = sorts.match /([\w\d]+) (A|DE)SC/gi

            if matches
              return @sort matches

            if sorts is 'id'
              sorts = '_id'

            @filter.options.sort ?= {}
            @filter.options.sort[sorts] = if value is 'DE' then -1 else 1
          else
            @filter.options.sort = _id: 1

          this

