module.exports = (app) ->

  app

  .module 'MongoDBConnector', [ 'Connector', 'MongoQuery', 'Type' ]

  .initializer ->

    @require
      mongo: 'mongodb'

    @include './orm'
    @include './collection'
    @include './cursor'

    @factory 'MongoClient', (mongo) ->
      mongo.MongoClient

    @factory 'ObjectID', (mongo) ->
      mongo.ObjectID

    @type 'ObjectID', (Types, Type, ObjectID) ->
      class ObjectId extends Type

        @swagger:

          schema: (v) ->
            type: 'string'
            pattern: '^[a-fA-F\\d]{24}$'

        @check: (v) ->
          return false if @absent v

          v instanceof ObjectID

        @parse: (v) ->
          return undefined if @absent v

          if v instanceof ObjectID
            return v

          if @function v.toString
            v = v.toString()

          if v.match /^[a-fA-F0-9]{24}$/
            return new ObjectID v

          undefined

    @connector 'MongoDB', (MongoORM, MongoClient) ->
      class MongoDB extends MongoORM

        @buildUrl: ({ username, password, port, hostname, database }) ->
          hostname = hostname or '127.0.0.1'
          port = port or 27017
          database = database or 'test'

          path = 'mongodb://'

          if username and password
            path += [ username, ':', password, '@' ].join ''
          path += [ hostname, ':', port ].join ''

          path + '/' + database

        @initialize: (@settings = {}, fn = ->) ->
          super

          @url = @buildUrl @settings

          @connect().asCallback fn

        @connect: ->
          if not @connecting
            return @_connect()

          new Promise (resolve, reject) =>
            if @connected
              return resolve @db

            @once 'connected', =>
              resolve @db

        @_connect: ->
          @connecting = true

          MongoClient.connect @url, @settings.options
            .then (db) =>
              @db = db
              @connected = true
              @emit 'connected', db
              db

        @disconnect: (cb = ->) ->
          @db.close()

          if cb
            process.nextTick cb

        @ping: (cb = ->) ->
          @db.collection('dummy').findOne { _id: 1 }, cb

        @execute: (opts, cb = ->) ->
          if typeof opts is 'string'
            tmp = opts
            opts = {}
            opts[tmp] = 1

          @db.command opts, cb

        @listCollections: (cb = ->) ->
          @db.listCollections().toArray cb

        @getCollectionNames: (cb = ->) ->
          @listCollections (err, collections) ->
            if err
              return cb(err)

            cb null, collections.map (collection) ->
              collection.name

        @createCollection: (name, opts, cb = ->) ->
          if typeof opts is 'function'
            return @createCollection name, {}, opts

          cmd = create: name

          Object.keys(opts).forEach (opt) ->
            cmd[opt] = opts[opt]

          @execute cmd, cb

        @stats: (scale, cb = ->) ->
          if typeof scale is 'function'
            return @stats 1, scale

          @execute dbStats: 1, scale: scale, cb

        @dropDatabase: (cb = ->) ->
          @execute 'dropDatabase', cb

        @createUser: (usr, cb = ->) ->
          cmd = extend { createUser: usr.user }, usr
          delete cmd.user

          @execute cmd, cb

        @dropUser: (username, cb = ->) ->
          @execute { dropUser: username }, cb

        @eval: (fn, args..., cb = ->) ->
          cmd =
            eval: fn.toString()
            args: args

          @execute cmd, (err, res) ->
            if err
              return cb err

            cb null, res.retval

        @getLastErrorObj: (cb = ->) ->
          @execute 'getLastError', cb

        @getLastError: (cb = ->) ->
          @execute 'getLastError', (err, res) ->
            if err
              return cb err

            cb null, res.err

        @toString: ->
          @name

