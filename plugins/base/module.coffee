module.exports = ->

  @factory 'Module', (Events, Utils) ->
    { property } = Utils

    class Module extends Events

      @mixin: (obj) ->
        @extend obj
        @inherit obj::

      @inherit: (obj) ->
        for key, value of obj when key isnt 'constructor'
          @::[key] = value
        @

      @extend: (obj, self) ->
        for key, value of obj when key isnt 'constructor'
          @[key] = value
        @

      @extends: (name, parent) ->

        child = new Function(
          'return function ' + name + '() {\n' +
          '  return ' + name + '.__super__.constructor.apply(this, arguments);\n' +
          '};'
        )()

        ctor = ->
          @constructor = child
          return

        for own key, value of parent
          child[key] = value
        
        ctor.prototype = parent.prototype
        
        child.prototype = new ctor
        child.__super__ = parent.prototype
        child

      @property: (cls, key, accessor, hidden = false) ->
        if arguments.length is 2
          return @property @, cls, key

        property cls, key, accessor, hidden

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

      $property: (key, accessor = {}, hidden = false) ->
        property @, key, accessor, hidden
