'use strict'

module.exports = ->

  @require
    HttpError: 'http-error'

  @include './param'

  @factory 'Route', (Types, Utils, path, HttpError, RouteParam) ->

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
          param.required = true

          if !param.source
            param.source = 'path'

          if param.source != 'path'
            throw new Error('Url parameters must have \'path\' as source but found \'' + param.source + '\'')

          if wildcard
            '(/*)'
          else
            '/([^\\/]+)'
        .replace /([\/.])/g, '\\$1'
        .replace /\*/g, '(.*)'

      new RegExp '^' + path + '$'

    class Route
      constructor: (@name, options, handler) ->
        if typeof options == 'function' or Array.isArray(options)
          handler = options
          options = {}

        @name = @name or 'root'

        @params = {}
        @keys = []

        for own key, val of options
          @[key] = val

        @middlewares = [
          @wrapHandler(handler).bind(@)
        ]

        @method = (@method or 'GET').toLowerCase()
        @regex = normalizePath @path, @keys, @params

        for name, param of @params
          @params[name] = new RouteParam name, param

      match: (req, path) ->
        if req.method.toLowerCase() isnt @method
          return false

        m = path.match(@regex)

        if !m
          return false

        req.params = {}

        errors = []

        for key, idx in @keys
          req.params[key] = m[idx + 1]

        for name, param of @params
          if missing = param.missing req
            missing.resource = @name or 'root'
            errors.push missing
          else if invalid = param.invalid req
            invalid.resource = @name or 'root'
            errors.push invalid

        if errors.length
          err = new HttpError.UnprocessableEntity 'Validation failed'
          err.errors = errors
          req.errors = err

        req.route = @

        true

      wrapHandler: (handler) ->
        args = @args
        route = @

        (req, res, next) ->
          arr = []

          console.log 'params', req.params

          for arg, idx in args
            arr[idx] = req.params[arg]

          idx = args.indexOf 'cb'

          arr[idx] = (err, json, headers, code) ->
            if err
              return next err

            res.json json, headers, code

          handler.apply null, arr

          return

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
          path: @path
          method: @method

        if @name
          route.name = @name

        if @description
          route.description = @description

        if Object.keys(@params).length
          route.params = @params

        route
