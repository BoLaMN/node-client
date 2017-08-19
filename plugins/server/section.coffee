'use strict'

module.exports = ->

  @include './route'
  @include './request'

  @factory 'Section', (Request, Route, utils, url) ->

    methods = [
      'head'
      'get'
      'put'
      'post'
      'delete'
      'patch'
      'upgrade'
      'options'
    ]

    class Section
      constructor: (@name, @path = '', description) ->
        @routes = {}
        @sections = {}

        @phases = [
          'initial', 'session', 'auth', 'parse',
          'routes', 'files', 'final',
        ]

        @middlewares = {}

        @phases.forEach (phase) =>
          @middlewares[phase] = []

        @errorHandlers = []

        if @path[0] isnt '/'
          @path = '/' + @path

        methods.forEach (method) =>
          @routes[method] = []

          @[method] = ((method, name, options, handler) =>
            if typeof options == 'function' or Array.isArray(options)
              handler = options
              options = {}

            options.method = method

            @_route name, options, handler
          ).bind @, method

        @del = @delete

        @handle = @_handle.bind @

      all: (method, route, options, handler) ->
        args = arguments
        methods.forEach (method) =>
          @[method].apply @, args
        @

      use: (phase, middleware) ->
        if not @middlewares[phase]
          @middlewares[phase] = []
          @phases.push phase

        @middlewares[phase].push.apply @middlewares[phase], utils.flatten(middleware)
        @

      error: (middleware) ->
        @errorHandlers.push.apply @errorHandlers, utils.flatten(middleware)
        @

      _route: (name, options, handler) ->
        route = new Route name, options, handler
        route.parent = this
        @routes[route.method].push route
        @

      section: (name, path, description) ->
        path = path or name

        if @sections[path]
          return @sections[path]

        section = new Section name, path, description
        section.parent = this

        @sections[path] = section

        section

      _handle: (req, res, next) ->
        req.locals ?= {}
        req.params ?= {}
        req.body   ?= {}

        if not req.parsedUrl
          req.parsedUrl = url.parse req.url, true
          req.query = req.parsedUrl.query

        path = req.parsedUrl.pathname
        method = req.method.toLowerCase()

        if methods.indexOf(method) is -1
          return next()

        route = @match req, path, method

        if not route
          return next()

        handler = route.parent

        middleware = {}
        errorHandlers = []

        while handler
          handler.phases.forEach (phase) ->
            middleware[phase] ?= []
            middleware[phase].unshift.apply middleware[phase], handler.middlewares[phase] or []
          
          errorHandlers.unshift.apply errorHandlers, handler.errorHandlers or []
          
          handler = handler.parent

        middleware.routes.push route.handler

        new Request middleware, errorHandlers
          .handle req, res, next

      match: (req, path, method) ->

        for route in @routes[method]
          if route.match req, path
            return route

        splitPath = path.split '/'

        if not splitPath[0]
          splitPath.shift()

        if splitPath.length
          section = @sections[splitPath[0]]

          if section
            handler = section.match req, path, method
            return handler if handler
          else
            for name, subsection of @sections
              handler = subsection.match req, path, method
              return handler if handler

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

        for path, section of @sections
          api.sections[path] = section

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

      toSwagger: (api = {}) ->

        for path, section of @sections
          section.toSwagger api

        for method, routes of @routes
          for route in routes
            if route.path isnt '/swagger.json'
              info = route.toSwagger()
              path = route.path
                .replace /\/:([\w\.\-\_]+)(\*?)/g, '/{$1}'
                .replace /\/$/, ''

              if info
                api.paths[path] ?= {}
                api.paths[path][method] = info

        api
