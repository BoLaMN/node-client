wrap = (fn) ->
  (args...) ->
    last = args[args.length - 1]
    ctx = @

    done = if typeof last == 'function' then args.pop() else ->

    if !fn
      return done.apply(@, [ null ].concat(args))

    if fn.length > args.length
      try
        return fn.apply(@, args.concat(done))
      catch e
        return done(e)

    sync(fn, done).apply @, args

promise = (done) ->
  (value) ->
    done null, value
    value

sync = (fn, done) ->
  ->

    try
      ret = fn.apply @, arguments
    catch err
      return done err

    if pret and 'function' == typeof ret.then
      end = promise done
      ret.then end, end
    else
      if ret instanceof Error
        done ret
      else done null, ret

    return

module.exports = wrap