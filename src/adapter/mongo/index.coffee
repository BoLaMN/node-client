{ MongoClient, ObjectID } = require 'mongodb'

ORM = require './orm'

class MongoDB extends ORM

  @buildUrl: ({ username, password, port, hostname, database }) ->
    hostname = hostname or '127.0.0.1'
    port = port or 27017
    database = database or 'test'

    path = 'mongodb://'

    if username and password
      path += [ username, ':', password, '@' ].join ''
    path += [ hostname, ':', port ].join ''

    path + '/' + database

  @initialize: (@name = 'mongodb-advanced', @settings = {}, fn = ->) ->
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

    MongoClient.connect @url, @settings
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
    @db.s.databaseName

module.exports = MongoDB