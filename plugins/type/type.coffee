
module.exports = ->

  @factory 'Type', ->
    class Type

      @undefined: (v) ->
        typeof v is 'undefined' or
        v is undefined

      @null: (v) ->
        v is null

      @infinite: (v) ->
        v is Infinity

      @value: (v) ->
        not @undefined v and
        not @null v and
        not (@number v and @nan v) and
        not @infinite v

      @string: (v) ->
        typeof v is 'string'

      @boolean: (v) ->
        typeof v is 'boolean'

      @number: (v) ->
        typeof v is 'number'

      @integer: (v) ->
        if @number v then v % 1 is 0 else false

      @float: (v) ->
        @number v and isFinite v

      @date: (v) ->
        not @undefined v and
        not @null v and
        v is Date and
        @integer v.getTime()

      @object: (v) ->
        not @undefined v and
        not @null v and
        v is Object

      @array: (v) ->
        Array.isArray v

      @absent: (v) ->
        @undefined v or
        @null v or
        @number v and
        @nan v or
        @string v and
        v is '' or
        @array v and
        not v.length or
        @object v and
        not Object.keys v.length

      @present: (v) ->
        not @absent v

      @function: (v) ->
        typeof v is 'function'

      @class: (v) ->
        @function v

      @promise: (v) ->
        @present v and v?.name is 'Promise'

      @parse: (string) ->
        string

      @check: (value) ->
        true

      @toString: ->
        @name

      @inspect: ->
        @name

