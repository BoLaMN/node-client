debug = require('debug')('loopback:connector:live')

ORM = require './live-orm'
KeyArray = require './key-array'

class Live extends ORM
  constructor: (@url, @dataSource) ->
    super

    @name = 'live'

    @data = {}
    @settings = @dataSource.settings or {}

    debug 'Settings: %j', @settings

  @initialize: (dataSource, callback) ->
    connector = new Live null, dataSource

    dataSource.connector = connector
    dataSource.connector.connect callback

    return

  getTypes: ->
    [ 'db', 'nosql', 'mongodb' ]

  getDefaultIdType: ->
    @dataSource.ObjectID

  define: (definition) ->
    super definition

    model = definition.model.modelName

    @collection model

    return

  collection: (model, data) ->
    name = @collectionName model
    
    id = @idName model
    prop = @_models[model].properties[id]

    if data 
      @data[name] = new KeyArray id, prop, data

    @data[name] ?= new KeyArray id, prop
    @data[name]

  collectionName: (model) ->
    modelClass = @_models[model]
    modelClass.settings[@name]?.collection or model

  connect: (callback) ->
    process.nextTick callback

  disconnect: (callback) ->
    debug 'disconnect'

    if callback
      process.nextTick callback

module.exports = Live