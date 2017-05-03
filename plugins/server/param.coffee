'use strict'

module.exports = ->

  @factory 'RouteParam', (Types) ->

    class RouteParam
      constructor: (@name, param) ->

        for own name, val of param
          @[name] = val

        switch @source
          when 'query', 'url'
            @type = @type or 'string'
          when undefined, 'body'
            @type = @type or 'json'
            @source = 'body'
          when 'context'
            @type = @type or 'object'
          else
            throw new Error "parameter source muste be 'context', url', 'query' or 'body'"

        @optional = not not @optional

        if @type instanceof RegExp
          RegExpType = Types.$get 'RegExp'

          @type = RegExpType.construct @type
        else if @type is 'string'
          @type = Types.$get @type

      missing: ({ match, body, parsedUrl }) ->
        { query } = parsedUrl

        if @optional
          return false

        exists =
          @source is 'body' and (@name of body) or
          @source is 'query' and (@name of query) or
          @source is 'url' and (@name of match)

        if exists
          return false

        field: @name
        source: @source
        code: 'missing_field'

      check: (obj) ->
        value = obj[@name]

        try
          value = @type.parse value
        catch e
          return

        if not @type.check value
          return

        value

      invalid: ({ match, body, parsedUrl, params }) ->
        { query } = parsedUrl

        value = switch @source
          when 'body'  then @check body
          when 'query' then @check query
          when 'url'   then @check match

        if value
          params[@name] = value
        else if @default
          params[@name] = @default
        else if @optional
          return
        else
          field: @name
          type_expected: @type.toString().toLowerCase()
          code: 'invalid'

      toObject: ->

        if not @type?.toString()?.toLowerCase()
          console.log 'missing type', @

        param =
          type: @type?.toString()?.toLowerCase()
          source: @source
          optional: @optional

        if @description
          param.description = @description

        param

      toJSON: ->
        @toObject()