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
          else
            throw new Error "parameter source muste be 'url', 'query' or 'body'"

        @optional = not not @optional

        if @type instanceof RegExp
          RegExpType = Types.$get 'RegExp'

          @type = RegExpType.construct @type
        else
          @type = Types.$get @type

      missing: ({ match, body, parsedUrl }) ->
        { query } = parsedUrl

        if @optional
          return false

        exists =
          @source is 'body' and !(@name of body) or
          @source is 'query' and !(@name of query) or
          @source is 'url' and !(@name of match)

        if exists
          return false

        field: @name
        source: @source
        code: 'missing_field'

      invalid: ({ match, body, parsedUrl, params }) ->
        { query } = parsedUrl

        invalid = false

        switch @source
          when 'body'
            if @optional and !(@name of body)
              break

            value = body[@name]

            if @optional and value == null
              break

            invalid = not @type.check(value)
          when 'query'
            if @optional and query[@name] == null
              break
            try
              value = @type.parse(query[@name])
            catch e
              invalid = true

            invalid = if invalid then true else not @type.check(value)
          when 'url'
            if @optional and match[@name] is null
              break

            value = match[@name]
            invalid = false

        if not invalid

          if value isnt {}
            params[@name] = value
          else if @default
            params[@name] = @default

          return false

        field: @name
        type_expected: @type.toString()
        code: 'invalid'

      toJSON: ->
        param =
          name: @name
          type: @type.toString()
          source: @source
          optional: @optional

        if @description
          param.description = @description

        param