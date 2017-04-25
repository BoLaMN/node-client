asCallback = require './utils/as-callback'

Events = require './emitter'
property = require './utils/property'

class Module extends Events

  @mixin: (obj) ->
    @extend obj
    @include obj::

  @include: (obj) ->
    for key, value of obj when key isnt 'constructor'
      @::[key] = value
    @

  @extend: (obj, self) ->
    for key, value of obj when key isnt 'constructor'
      @[key] = value
    @

  @property: (cls, key, accessor) ->
    if arguments.length is 2
      return @property @, cls, key

    property cls, key, accessor

  constructor: ->
    super

module.exports = Module