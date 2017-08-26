'use strict'

module.exports = ->

  @factory 'RouteParam', (Types, swagger, utils, Models) ->

    class RouteParam
      constructor: (@name, param) ->

        for own name, val of param
          @[name] = val

        switch @source
          when 'query', 'path', 'header'
            @type = @type or 'string'
          when undefined, 'body'
            @type = @type or 'json'
            @source = 'body'
          when 'context'
            @type = @type or 'object'
          else
            throw new Error "parameter source muste be 'context', path', 'query', 'header' or 'body'"

        @required = not not @required

        if @type instanceof RegExp
          RegExpType = Types.get 'RegExp'

          @fn = RegExpType.construct @type

      missing: ({ params, body, parsedUrl, headers }) ->
        { query } = parsedUrl

        if not @required
          return false

        if @root
          return false

        exists =
          @source is 'context' or
          @source is 'body' and (@name of body) or
          @source is 'query' and (@name of query) or
          @source is 'path' and (@name of params) or
          @source is 'header' and (@name of headers)

        if exists
          return false

        field: @name
        source: @source
        code: 'missing_field'

      check: (obj) ->
        value = if @root then obj else obj[@name]

        @fn ?= Types.get @type
        @fn ?= Models.get @type

        try
          value = @fn.parse value
        catch e
          return

        if not @fn.check value
          return

        value

      invalid: (req) ->
        { body, headers, parsedUrl, params, locals } = req
        { query } = parsedUrl

        value = switch @source
          when 'context' then locals
          when 'header'  then @check headers
          when 'body'    then @check body
          when 'query'   then @check query
          when 'path'    then @check params

        if value
          req.params[@name] = value
          return false
        else if @default
          req.params[@name] = @default
          return false
        else if not @required
          return
        else
          field: @name
          type_expected: @type
          code: 'invalid'

      toObject: ->

        if not @type
          console.log 'missing type', @

        param =
          type: @type
          source: @source
          required: @required

        if @description
          param.description = @description

        param

      toJSON: ->
        @toObject()

      toSwagger: ->
        utils.extend
          in: @source
          name: @name
          description: @description
          required: @required
        , swagger.buildFromSchemaType @