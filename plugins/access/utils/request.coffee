typeis = require 'type-is'

module.exports = ->

  @factory 'AccessReq', (InvalidArgumentError) ->

    class AccessReq
      constructor: (options) ->
        { headers, body, @method, @query } = options

        @body = body or {}
        @models = options.app.models
        @issuer = options.app.get 'issuer'

        if not headers
          throw new InvalidArgumentError 'HEADERS'

        if not @method
          throw new InvalidArgumentError 'METHOD'

        if not @query
          throw new InvalidArgumentError 'QUERY'

        @headers = {}

        for field of headers
          if headers.hasOwnProperty(field)
            @headers[field.toLowerCase()] = options.headers[field]

        for property of options
          if options.hasOwnProperty(property) and !@[property]
            @[property] = options[property]

        return

      get: (field) ->
        @headers[field.toLowerCase()]

      ###*
      # Check if the content-type matches any of the given mime type.
      ###

      is: (types) ->
        if not Array.isArray(types)
          types = [].slice.call(arguments)

        typeis(this, types) or false
