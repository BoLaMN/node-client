'use strict'

module.exports = ->

  @factory 'MongoQueryWhere', (ObjectID) ->
    class MongoQueryWhere
      constructor: (conditions, @model) ->
        @query = {}
        @parse conditions
        @

      ###*
      # Set "where" condition
      #
      # @param {String} key - key
      # @param {Mixed} value - value
      # @api public
      ###

      parse: (where) ->

        if typeof where isnt 'object'
          return where

        reparse = (cond, prop) =>
          if prop is @model.primaryKey
            prop = '_id'

          if typeof @[prop] is 'function'
            @[prop] cond
          else if cond instanceof ObjectID
            @query[prop] = cond
          else if typeof cond isnt 'object'
            @query[prop] = cond
          else @parse cond

        Object.keys(where).forEach (prop) ->
          cond = where[prop]

          if Array.isArray cond
            items = cond.map (v) => @parse cond
            if @[prop]?()
              @[prop] items
            else
              @[prop] = items
          else
            reparse cond, prop

        this

      ###*
      # Match documents using $elemMatch
      #
      # @param {String} key
      # @param {Object} value
      # @api public
      ###

      matches: (key, value) ->
        if @lastKey
          value = key
          key = @lastKey

          @lastKey = null

        @query[key] = $elemMatch: value

        this

      match: ->
        @matches.apply this, arguments

      ###*
      # Between
      #
      # @param {String} key - key
      # @param {Mixed} value - value
      # @api public
      ###

      between: (key, [ gte, lte ]) ->
        @lastKey = key
        @gte gte

        @lastKey = key
        @lte lte

        this

      ###*
      # Same as .where(), only less flexible
      #
      # @param {String} key - key
      # @param {Mixed} value - value
      # @api public
      ###

      inq: (key, value) ->
        @in key, value

      neq: (key, value) ->
        @ne key, value

      equals: (value) ->
        key = @lastKey

        @lastKey = null
        @query[key] = value

        this

      ###*
      # Set property that must or mustn't exist in resulting docs
      #
      # @param {String} key - key
      # @param {Boolean} exists - exists or not
      # @api public
      ###

      exists: (key, exists = true) ->
        if @lastKey
          exists = key
          key = @lastKey

          @lastKey = null

        @query[key] = $exists: exists

        this

    [ 'lt', 'lte'
      'gt', 'gte'
      'in', 'nin'
      'ne'
    ].forEach (method) ->

      MongoQueryWhere::[method] = (key, value) ->
        if @lastKey
          value = key
          key = @lastKey

          @lastKey = null

        operator = '$' + method
        hasValue = value isnt undefined

        if hasValue
          @query[key] ?= {}
          @query[key][operator] = value
        else
          @query[operator] = key

        this

      return

    [ 'or', 'nor', 'and' ].forEach (method) ->

      MongoQueryWhere::[method] = (args...) ->
        operator = '$' + method

        @query[operator] = @parse args

        this

      return

    MongoQueryWhere
