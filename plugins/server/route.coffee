'use strict'

module.exports = ->

  @require
    HttpError: 'http-error'

  @factory 'Route', (Types, Utils, url, HttpError) ->

    wrapHandler = (handler) ->
      (req, res, next) ->
        handler req.params or {}, (err, json, headers, code) ->
          if err
            return next(err)

          res.json json, headers, code

    normalizePath = (path, keys, params) ->
      for name of params
        param = params[name]

        if typeof param == 'string' or param instanceof RegExp
          params[name] = type: param

      path = path.concat('/?')
        .replace /\/:([\w\.\-\_]+)(\*?)/g, (match, key, wildcard) ->
          keys.push key

          if !params[key]
            params[key] = {}

          param = params[key]
          param.type = param.type or 'string'
          param.optional = false

          if !param.source
            param.source = 'url'

          if param.source != 'url'
            throw new Error('Url parameters must have \'url\' as source but found \'' + param.source + '\'')

          if wildcard
            '(/*)'
          else
            '/([^\\/]+)'
        .replace /([\/.])/g, '\\$1'
        .replace /\*/g, '(.*)'

      new RegExp '^' + path + '$'

    class Route
      constructor: (@route, options, handler, types) ->
        if typeof options == 'function' or Array.isArray(options)
          types = handler
          handler = options
          options = {}

        for own key, val of options
          @[key] = val

        @types = types or new Types

        @middlewares = Utils.flatten handler

        @middlewares = @middlewares.map (handler) ->
          if handler.length == 2
            handler = wrapHandler(handler)
          handler

        @middlewares.unshift @decodeParams.bind @

        @method = (@method or 'GET').toLowerCase()

        @keys = []

        @routeRe = normalizePath @route, @keys, @params
        @params = @normalizeParams @types, @params or {}

      match: (req, path) ->
        m = path.match(@routeRe)

        if !m
          return false

        match = {}

        i = 0

        while i < @keys.length
          value = m[i + 1]
          key = @keys[i]

          param = @params[key]
          type = param.type

          if param.optional and value == null
            match[key] = value
            i++
            continue

          try
            value = type.parse(value)
          catch e
            return false

          if !type.check(value)
            return false

          match[key] = value
          i++

        req.match = match

        true

      normalizeParams: (types, params) ->
        for name of params
          param = params[name]

          if param.source == 'query'
            param.type = param.type or 'string'
          else if !param.source or param.source == 'body'
            param.type = param.type or 'json'
            param.source = 'body'
          else if param.source == 'url'
            param.type = param.type or 'string'
          else
            throw new Error('parameter source muste be \'url\', \'query\' or \'body\'')

          param.optional = ! !param.optional

          if param.type instanceof RegExp
            RegExpType = @types.get 'RegExp'

            param.type = new RegExpType param.type

          param.type = types.get(param.type)

        params

      decodeParams: (req, res, next) ->
        urlParams = req.match

        if !urlParams
          return

        body = req.body or {}
        query = req.parsedUrl.query

        req.params = req.params or {}

        errors = []

        EMPTY = {}

        for key, param of @params
          if !param.optional and (param.source == 'body' and !(key of body) or param.source == 'query' and !(key of query) or param.source == 'url' and !(key of urlParams))
            errors.push
              resource: @name or 'root'
              field: key
              source: param.source
              code: 'missing_field'
          else
            type = param.type
            value = EMPTY
            isValid = true

            switch param.source
              when 'body'
                if param.optional and !(key of body)
                  break

                value = body[key]

                if param.optional and value == null
                  break

                isValid = type.check(value)
              when 'query'
                if param.optional and query[key] == null
                  break
                try
                  value = type.parse(query[key])
                catch e
                  isValid = false

                isValid = if isValid == false then false else type.check(value)
              when 'url'
                if param.optional and urlParams[key] == null
                  break

                value = urlParams[key]
                isValid = true

            if !isValid
              errors.push
                resource: @name or 'root'
                field: key
                type_expected: type.toString()
                code: 'invalid'
            else
              if value != EMPTY
                req.params[key] = value
              else if 'default' of param
                req.params[key] = param.default

        if errors.length
          err = new HttpError.UnprocessableEntity 'Validation failed'
          err.errors = errors
          return next(err)

        next()


      describe: ->
        @
