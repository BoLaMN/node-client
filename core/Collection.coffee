'use strict'

proto = Array.prototype

class Collection
  constructor: (data, type, parent) ->
    collection = []

    if not type
      type = data[0]?.constructor
    
    if Array.isArray type
      type = type[0]

    @injectClassMethods collection, type, parent

    data.forEach (item) ->
      collection.push item

    return collection

  injectClassMethods: (collection, type, parent) ->

    define = (prop, desc) ->
      return unless desc?
      
      Object.defineProperty collection, prop,
        writable: false
        enumerable: false
        value: desc

    for key, value of @
      define key, value

    define 'parent', parent
    define 'itemType', type

    collection

  concat: ->
    arr = proto.concat.apply @, arguments
    new @constructor arr

  map: ->
    arr = proto.map.apply @, arguments
    new @constructor arr

  filter: ->
    arr = proto.filter.apply @, arguments
    new @constructor arr

  build: (data = {}) ->
    if @itemType and data instanceof @itemType 
      data 
    else 
      new @itemType data

  push: (args) ->
    if not Array.isArray args
      args = [ args ]

    added = args.map @build.bind(@)

    count = @length

    added.forEach (add) =>
      count = proto.push.apply @, [ add ]

    count

  splice: (index, count, elements) ->
    args = [ index, count ]

    added = []

    if elements
      if not Array.isArray elements
        elements = [ elements ]

      added = elements.map @build.bind(@)

      if added.length
        args.push added

    proto.splice.apply @, args

  unshift: (args) ->
    if not Array.isArray args
      args = [ args ]

    added = args.map @build.bind(@)

    count = @length

    added.forEach (add) =>
      count = proto.unshift.apply @, [ add ]

    count

  toObject: (onlySchema, removeHidden, removeProtected) ->
    items = []
    
    @forEach (item) ->
      if item and typeof item is 'object' and item.toObject
        items.push item.toObject(onlySchema, removeHidden, removeProtected)
      else
        items.push item

    items

  toJSON: ->
    @toObject true

  toString: ->
    JSON.stringify @toJSON()

module.exports = Collection