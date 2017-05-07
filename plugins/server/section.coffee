'use strict'

module.exports = ->

  @include './route'
  @include './request'

  @factory 'Section', (Request, Route, Utils, url) ->

    class Section
      constructor: (@name = '', description) ->
        @routes = {}
        @sections = {}

        @middlewares = []
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
        @methods.forEach (method) =>
          @[method].apply @, args
        @

      use: (middleware) ->
        @middlewares.push.apply @middlewares, Utils.flatten(middleware)
        @

      error: (middleware) ->
        @errorHandlers.push.apply @errorHandlers, Utils.flatten(middleware)
        @

      _route: (name, options, handler) ->
        route = new Route name, options, handler
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

      _handle: (req, res, next) ->

        if !req.parsedUrl
          req.parsedUrl = url.parse(req.url, true)

        path = req.parsedUrl.pathname

        req.params = req.params or {}
        method = req.method.toLowerCase()

        if @methods.indexOf(method) == -1
          return next()

        handler = @match req, path, method

        if not handler
          return next()

        new Request @middlewares, @errorHandlers, handler
          .handle req, res, next

      match: (req, path, method) ->
        splitPath = path.split '/'

        if not splitPath[0]
          splitPath.shift()

        if splitPath.length
          section = @sections[splitPath[0]]

          if section
            subPath = '/' + splitPath.slice(1).join('/')
            handler = section.match req, subPath, method
          else
            for name, section of @sections
              handler = section.match req, path, method

          if handler
            return handler

        for route in @routes[method]
          if route.match req, path
            return route.middlewares

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
