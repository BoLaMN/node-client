Model = require './persisted-model'
Mongo = require './adapter/mongo'

Adapter = Mongo.define 'db'

Album = Model
  .define 'Album',
    {'name': { 'type': 'number' }, 'id': { 'type': 'number' }, 'photo': { 'type': 'Photo' } }
  .attribute 'phone', { 'type': 'string' }
  .hasMany 'Photo'
  .adapter Adapter

Photo = Model
  .define 'Photo', {'name': { 'type': 'number' }, 'id': { 'type': 'number' } }
  .adapter Adapter
  .observe 'loaded', (ctx, next) ->
    console.log 'loaded observe', ctx
    next()

n = new Album { name: 'test', id: 201, photo: { name: 'we' } }
n.save()
n.fire 'loaded', ->
  n.save().then (data) ->
    console.log data

    n.$events
