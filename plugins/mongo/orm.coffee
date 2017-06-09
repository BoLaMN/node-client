{ parseUpdateData } = require './utils'

module.exports = ->

  @factory 'MongoORM', (Adapter, MongoQuery, KeyArray, MongoCollection, Utils, ObjectID, debug, inspect) ->
    { buildOptions } = Utils

    class MongoORM extends Adapter

      constructor: (model) ->
        super

        if not model.attributes[model.primaryKey]
          model.attribute model.primaryKey,
            id: true
            type: 'objectid'

        @model = model

      ###*
      # Execute a mongodb command
      # @param {String} model The model name
      # @param {String} command The command name
      # @param [...] params Parameters for the given command
      ###
      execute: (command, args...) ->
        @constructor.connect().then (db) =>
          @collection ?= new MongoCollection db.collection @model.name

          context =
            hookState: {}
            model: @model
            collection: @collection
            command: command
            params: args

          @collection[command].apply @collection, args

      ###*
      # Count the number of instances for the given model
      #
      # @param {String} model The model name
      # @param {Function} [cb] The cb function
      # @param {Object} filter The filter for where
      #
      ###
      count: (filter, options = {}, cb = ->) ->
        debug 'count', filter

        if typeof filter is 'object'
          delete filter.fields

        { filter } = new MongoQuery filter, @model
        { where } = filter

        @execute 'count', where
          .tap (results) ->
            debug 'count.cb', inspect(
              filter: filter
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Create a new model instance for the given data
      # @param {String} model The model name
      # @param {Object} data The model data
      # @param {Function} [cb] The cb function
      ###
      create: (data, options = {}, cb = ->) ->
        debug 'create', data

        if not Array.isArray data
          data = [ data ]

        model = @model

        @execute 'insert', @normalizeIds(data), safe: true
          .tap (results) ->
            debug 'create.cb', inspect(
              options: options
              results: results
            , false, null)
          .then ({ insertedIds, insertedCount }) ->
            intances = data.map (doc, i) ->
              doc.id = insertedIds[i]
              new model doc, buildOptions(options, i)
            if insertedCount is 1
              intances[0]
            else intances
          .asCallback cb

      ###*
      # Delete a model instance by id
      # @param {String} model The model name
      # @param {*} id The id value
      # @param [cb] The cb function
      ###
      destroyById: (id, options = {}, cb = ->) ->
        debug 'delete', id

        @execute 'remove', { _id: id }, true
          .tap (results) ->
            debug 'delete.cb', inspect(
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Delete all instances for the given model
      # @param {String} model The model name
      # @param {Object} [where] The filter for where
      # @param {Function} [cb] The cb function
      ###
      destroy: (filter = {}, options = {}, cb = ->) ->
        filter = where: where

        debug 'destroy', filter

        if typeof filter is 'object'
          delete filter.fields

        { filter } = new MongoQuery filter, @model
        { where, fields } = filter

        @execute 'remove', where, options
          .then (results) ->
            if not Array.isArray results
              results = [ results ]
            results.map (result) ->
              id: result
          .tap (results) ->
            debug 'destroyAll.cb', inspect(
              filter: filter
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Check if a model instance exists by id
      # @param {String} model The model name
      # @param {*} id The id value
      # @param {Function} [cb] The cb function
      #
      ###
      exists: (id, options = {}, cb = ->) ->
        debug 'exists', id

        @execute 'findOne', { _id: id }, options
          .tap (results) ->
            debug 'exists.cb', inspect(
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Find matching model instances by the filter
      #
      # @param {String} model The model name
      # @param {Object} filter The filter
      # @param {Function} [cb] The cb function
      ###
      find: (filter, options = {}, cb = ->) ->
        debug 'find', filter

        { filter } = new MongoQuery filter, @model
        { where, include, aggregate, fields } = filter

        if aggregate.length
          aggregate.unshift '$match': where

          Object.keys(options).forEach (option) ->
            object = {}
            object[option] = options['$' + option]
            aggregate.push object

          debug 'find.aggregate', inspect aggregate, false, null

          promise = @execute 'aggregate', aggregate
        else
          promise = @execute 'find', where, fields, options

        promise
          .then (cursor) =>
            cursor.mapArray @model, buildOptions(options)
          .then (data) =>
            @model.include data, include, options
          .tap (results) =>
            debug 'find.cb', inspect(
              model: @model.name
              filter: filter
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Find a model instance by id
      # @param {String} model The model name
      # @param {*} id The id value
      # @param {Function} [cb] The cb function
      ###
      findOne: (filter, options = {}, cb = ->) ->
        debug 'findOne', filter

        { filter } = new MongoQuery filter, @model
        { where, include, fields } = filter

        @execute 'findOne', where, fields
          .then (results) =>
            new @model results, buildOptions(options)
          .tap (results) =>
            debug 'findOne.cb', inspect(
              model: @model.name
              filter: filter
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Find a matching model instances by the filter
      # or create a new instance
      #
      # Only supported on mongodb 2.6+
      #
      # @param {String} model The model name
      # @param {Object} data The model instance data
      # @param {Object} filter The filter
      # @param {Function} [cb] The cb function
      ###
      findOrCreate: (filter = {}, data, cb = ->) ->
        debug 'findOrCreate', filter, data

        { filter } = new MongoQuery filter, @model
        { where, aggregate, fields } = filter

        query =
          projection: fields
          sort: sort
          upsert: true

        @execute 'findOneAndUpdate', where, { $setOnInsert: data }, query
          .then (results) =>
            new @model results, buildOptions(options)
          .tap (results) =>
            debug 'findOrCreate.cb', inspect(
              model: @model.name
              filter: filter
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Replace properties for the model instance data
      # @param {String} model The name of the model
      # @param {*} id The instance id
      # @param {Object} data The model data
      # @param {Object} options The options object
      # @param {Function} [cb] The cb function
      ###
      replaceById: (id, data, options = {}, cb = ->) ->
        debug 'replaceById', id, data

        @replaceWithOptions id, data, upsert: false
          .tap (results) =>
            debug 'replaceById.cb', inspect(
              model: @model.name
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Replace model instance if it exists or create a new one if it doesn't
      #
      # @param {String} model The name of the model
      # @param {Object} data The model instance data
      # @param {Object} options The options object
      # @param {Function} [cb] The cb function
      ###
      replaceOrCreate: (data, options = {}, cb = ->) ->
        debug 'replaceOrCreate', data

        @replaceWithOptions null, data, upsert: true
          .tap (results) =>
            debug 'replaceOrCreate.cb', inspect(
              model: @model.name
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Update a model instance with id
      # @param {String} model The name of the model
      # @param {Object} id The id of the model instance
      # @param {Object} data The property/value pairs to be
      #                 updated or inserted if {upsert: true}
      #                 is passed as options
      # @param {Object} options The options you want to pass
      #                 for update, e.g, {upsert: true}
      # @cb {Function} [cb] cb function
      ###
      replaceWithOptions: (id, data, options = {}, cb = ->) ->
        debug 'updateWithOptions', id, data

        id = _id: id or data[ @model.primaryKey ]

        @execute 'update', id, @normalizeId(data), options
          .then (results) =>
            new @model results, buildOptions(options)
          .tap (results) =>
            debug 'updateWithOptions.cb', inspect(
              model: @model.name
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Save the model instance for the given data
      # @param {String} model The model name
      # @param {Object} data The model data
      # @param {Function} [cb] The cb function
      ###
      save: (data, options = {}, cb = ->) ->
        debug 'save', data

        @execute 'save', @normalizeId(data), options
          .then (results) =>
            new @model results, buildOptions(options)
          .tap (results) =>
            debug 'save.cb', inspect(
              model: @model.name
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Update all matching instances
      # @param {String} model The model name
      # @param {Object} where The search criteria
      # @param {Object} data The property/value pairs to be updated
      # @cb {Function} cb cb function
      ###
      update: (filter, data, options = {}, cb = ->) ->
        debug 'update', filter, data

        if typeof filter is 'object'
          delete filter.fields

        { filter } = new MongoQuery filter, @model
        { where, aggregate, fields } = filter

        @execute 'update', where, @normalizeId(data), options
          .tap (results) =>
            debug 'update.cb', inspect(
              model: @model.name
              filter: filter
              options: options
              results: results
            , false, null)
          .asCallback cb, spread: true

      updateAll: MongoORM::update

      ###*
      # Update properties for the model instance data
      # @param {String} model The model name
      # @param {Object} data The model data
      # @param {Function} [cb] The cb function
      ###
      updateAttributes: (id, data, options = {}, cb = ->) ->
        debug 'updateAttributes', id, data

        id = id or data[ @model.primaryKey ]

        data = parseUpdateData data
        sort = [ '_id', 'asc' ]

        @execute 'findAndModify', { _id: id }, @normalizeId(data), sort
          .tap (results) =>
            debug 'updateAttributes.cb', inspect(
              model: @model.name
              options: options
              results: results
            , false, null)
          .asCallback cb

      ###*
      # Update if the model instance exists with the same
      # id or create a new instance
      #
      # @param {String} model The model name
      # @param {Object} data The model instance data
      # @param {Function} [cb] The cb function
      ###
      updateOrCreate: MongoORM::save

      normalizeId: (value) ->
        value = value.toObject?() or value
        id = @model.primaryKey

        if value[id] instanceof ObjectID
          value._id = value[id]
        else if @matchMongoId value[id]
          value._id = ObjectID value[id]
        else
          value._id = value[id] or ObjectID.createPk()

        delete value[id]

        value

      normalizeIds: (values) ->
        values.map @normalizeId.bind(@)

      matchMongoId: (id) ->
        if not id?
          return false

        if typeof id.toString != 'undefined'
          id = id.toString()

        id.match /^[a-fA-F0-9]{24}$/

