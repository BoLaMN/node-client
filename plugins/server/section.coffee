'use strict'

module.exports = ->

  @include './route'

  @factory 'Section', (Route, Utils, url) ->

    class Section
      constructor: (@name = '', description) ->
        @routes = {}
        @sections = {}

        @middlewares = []
        @globals = []
        @errorHandlers = []

        @methods = [
          'head'
          'get'
          'put'
          'post'
          'delete'
          'patch'
          'upgrade'
          'options'
        ]

        @methods.forEach (method) =>
          @routes[method] = []

          @[method] = ((method, name, route, options, handler) =>
            if typeof options == 'function' or Array.isArray(options)
              handler = options
              options = {}
            options.method = method

            @_route name, route, options, handler
          ).bind @, method

        @del = @delete

        @handle = @_handle.bind @

      all: (method, route, options, handler) ->
        args = arguments
        @methods.forEach (method) =>
          @[method].apply @, args
        @

      global: (middleware) ->
        @globals.push.apply @globals, Utils.flatten(middleware)
        @

      use: (middleware) ->
        @middlewares.push.apply @middlewares, Utils.flatten(middleware)
        @

      error: (middleware) ->
        @errorHandlers.push.apply @errorHandlers, Utils.flatten(middleware)
        @

      _route: (name, route, options, handler) ->
        route = new Route name, route, options, handler
        route.parent = this
        @routes[route.method].push route
        @

      section: (name, description) ->
        if @sections[name]
          return @sections[name]

        section = new Section name, description
        section.parent = this

        @sections[name] = section

        section

      _rootHandler: (req, res) ->
        @handle req, res, (err) ->
          if err
            res.statusCode = err.code or err.statusCode or 500
            res.end err.message or err.toString
          else
            res.statusCode = 404
            res.end 'cannot ' + req.method

      _handle: (req, res, next) ->
        that = this

        processNext = ->
          handler = middleware[i++]

          if !handler or i > middleware.length
            return next()

          handler req, res, (err) ->
            if err
              return that.handleError(errorHandlers, err, req, res, next)

            processNext()

        if arguments.length == 2
          return @_rootHandler.apply(this, arguments)

        if arguments.length == 3
          req = arguments[0]
          res = arguments[1]

          next = arguments[2]

          if !req.parsedUrl
            req.parsedUrl = url.parse(req.url, true)

          path = req.parsedUrl.pathname

        req.params = req.params or {}
        method = req.method.toLowerCase()

        if @methods.indexOf(method) == -1
          return next()

        handler = @match(req, path, method)

        if !handler
          return next()

        middleware = []
        errorHandlers = []

        while handler
          middleware.unshift.apply middleware, handler.middlewares or []
          errorHandlers.unshift.apply errorHandlers, handler.errorHandlers or []

          handler = handler.parent

        if @globals.length
          middleware.splice.apply middleware, [
            1
            0
          ].concat(@globals)

        i = 0

        processNext()

      handleError: (errorHandlers, err, req, res, next) ->
        i = 0

        processNext = (err) ->
          if !err
            return next()

          handler = errorHandlers[i++]

          if !handler or i > errorHandlers.length
            return next(err)

          handler err, req, res, processNext

          return

        processNext err

        return

      match: (req, path, method) ->
        splitPath = path.split '/'

        if not splitPath[0]
          splitPath.shift()

        if splitPath.length
          section = @sections[splitPath[0]]

          if section
            subPath = '/' + splitPath.slice(1).join('/')
            handler = section.match req, subPath, method

            if handler
              return handler

        methodRoutes = @routes[method]
        i = 0

        while i < methodRoutes.length
          route = methodRoutes[i]

          if route.match req, path
            return route

          i++

        return

      toObject: ->
        api = @toJSON()

        if api.routes
          for method, routes of api.routes
            for route, idx in routes
              api.routes[method][idx] = route.toObject()

        if api.sections
          for key, section of api.sections
            api.sections[key] = section.toObject()

        api

      toJSON: ->
        api = {}

        if @description
          api.description = @description

        api.sections = {}

        for name, section of @sections
          api.sections[name] = section

        if not Object.keys(api.sections).length
          delete api.sections

        api.routes = {}

        for method, routes of @routes
          api.routes[method] = []

          for route in routes
            api.routes[method].push route

          if not api.routes[method].length
            delete api.routes[method]

        if not Object.keys(api.routes).length
          delete api.routes

        api
