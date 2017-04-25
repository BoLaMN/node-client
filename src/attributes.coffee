extend = require './utils/extend'
clone = require './utils/clone'

Storage = require './storage'
Module = require './module'
Cast = require './cast'

toString = Object::toString

class Attribute extends Module
  @include Cast::

  @attribute: (name, type, options) ->
    @attributes ?= new Storage

    exists = @attributes.$get name

    if exists
      return @

    switch toString.call type
      when '[object String]', '[object Array]'
        options ?= {}
        options.type = type
      when '[object Undefined]', '[object Null]'
        options = type: 'any'
      when '[object Object]'
        options = type
      when '[object Function]'
        options =
          fn: type
          type: type.name

    if options.id
      @primaryKey = name

    attr = new Attribute name, options

    @attributes.$define name, attr

    @

  constructor: (name, options = {}) ->
    super

    for own key, value of options
      @[key] = value

    @emit 'define', @, name, options

    @

module.exports = Attribute
