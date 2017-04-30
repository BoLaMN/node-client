'use strict'

module.exports = ->

  @require
    HttpError: 'http-error'

  @include './param'

  @factory 'Route', (Types, Utils, url, HttpError, RouteParam) ->

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
      constructor: (@route, options, handler) ->
        if typeof options == 'function' or Array.isArray(options)
          handler = options
          options = {}

        @params = {}
        @keys = []

        for own key, val of options
          @[key] = val

        @middlewares = Utils.flatten handler

        @middlewares = @middlewares.map (handler) ->
          if handler.length == 2
            handler = wrapHandler(handler)
          handler

        @middlewares.unshift @decodeParams.bind @

        @method = (@method or 'GET').toLowerCase()
        @routeRe = normalizePath @route, @keys, @params

        for name, param of @params
          @params[name] = new RouteParam name, param

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

      decodeParams: (req, res, next) ->
        if not req.match
          return

        req.params = req.params or {}

        errors = []

        for key, param of @params
          if missing = param.missing req
            missing.resource = @name or 'root'
            errors.push missing
          else if invalid = param.invalid req
            invalid.resource = @name or 'root'
            errors.push invalid

        if errors.length
          err = new HttpError.UnprocessableEntity 'Validation failed'
          err.errors = errors

        next err

      toObject: ->
        route = @toJSON()

        if not route.params
          return route

        params = {}

        for name, param of route.params
          params[name] = param.toObject()

        if Object.keys(params).length
          route.params = params

        route

      toJSON: ->
        route =
          route: @route
          method: @method

        if @name
          route.name = @name

        if @description
          route.description = @description

        if Object.keys(@params).length
          route.params = @params

        route
