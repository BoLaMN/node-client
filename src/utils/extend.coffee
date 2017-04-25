extend = (target, args...) ->
  args.forEach (source) ->
    return unless source

    for own key of source
      if source[key] isnt undefined
        target[key] = source[key]

  target

module.exports = extend