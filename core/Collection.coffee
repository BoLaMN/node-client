'use strict'

{ values } = require './Utils'

toFunction = require './ToFunction'

proto = Array.prototype

class Collection
  constructor: (data) ->
    collection = []

    values(data).forEach (item) ->
      collection.push item

    @injectClassMethods collection

    return collection

  injectClassMethods: (collection) ->

    define = (prop, desc) ->
      Object.defineProperty collection, prop,
        writable: false
        enumerable: false
        value: desc

    for key, value of @
      define key, value

    collection

  concat: ->
    arr = proto.concat.apply @, arguments
    new @constructor arr

  filter: (predicate) ->
    fn = toFunction predicate
    arr = proto.filter.apply @, [ fn ]
    new @constructor arr

module.exports = Collection