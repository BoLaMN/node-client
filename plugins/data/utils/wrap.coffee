module.exports = ->

  @decorator 'Utils', (Utils) ->

    sync = (fn, done) ->
      ->
        try
          ret = fn.apply(this, arguments)
        catch err
          return done(err)

        if promise(ret)
          ret.then (value) ->
            done null, value
            rvalue
          , done
        else
          if ret instanceof Error then done(ret) else done(null, ret)

        return

    promise = (value) ->
      value and 'function' == typeof value.then

    once = (fn) ->
      ->
        ret = fn.apply(this, arguments)
        fn = noop
        ret

    Utils.wrap = (fn, done) ->
      done = once(done or noop)

      ->
        i = arguments.length
        args = new Array(i)

        while i--
          args[i] = arguments[i]

        ctx = this

        if !fn
          return done.apply(ctx, [ null ].concat(args))

        if fn.length > args.length
          try
            return fn.apply(ctx, args.concat(done))
          catch e
            return done(e)

        sync(fn, done).apply ctx, args

    Utils