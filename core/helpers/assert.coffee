module.exports = ->

  @factory 'assert', ->

    class AssertionError extends Error
      constructor: (message, props, ssf) ->
        super

        @message = message or 'Unspecified AssertionError'

        for own key, value of props
          @[key] = props[key]

        ssf = ssf or arguments.callee

        if ssf and Error.captureStackTrace
          Error.captureStackTrace this, ssf
        else
          try
            throw new Error
          catch e
            @stack = e.stack

      name: 'AssertionError'

      toJSON: (stack = false) ->
        props = {}

        for own key, value of @
          if key is 'stack' and not stack
            return
          props[key] = value

        props

    (expr, msg, ssf) ->
      if not expr
        throw new AssertionError msg, null, ssf or arguments.callee

      return