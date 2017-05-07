module.exports = ->

  @factory 'Module', (Events, Utils) ->
    { property } = Utils

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

      @type: (val) ->
        if val is null
          return 'null'

        s = Object::toString.call val

        t = s.match(/\[object (.*?)\]/)[1].toLowerCase()

        if t is 'number'
          if isNaN val
            return 'nan'

          if not isFinite val
            return 'infinity'

        t

      constructor: ->
        super
