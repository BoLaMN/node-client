module.exports = ->

  @factory 'Ops', (TypeOf, Dot, Eql) ->
    ###*
    # $ne: not equal.
    ###

    $ne: (matcher, val) ->
      not Eql(matcher, val)

    ###*
    # $gt: greater than.
    ###

    $gt: (matcher, val) ->
      TypeOf(matcher) is 'number' and val > matcher

    ###*
    # $gte: greater than equal.
    ###

    $gte: (matcher, val) ->
      TypeOf(matcher) is 'number' and val >= matcher

    ###*
    # $lt: less than.
    ###

    $lt: (matcher, val) ->
      TypeOf(matcher) is 'number' and val < matcher

    ###*
    # $lte: less than equal.
    ###

    $lte: (matcher, val) ->
      TypeOf(matcher) is 'number' and val <= matcher

    ###*
    # $regex: supply a regular expression as a string.
    ###

    $regex: (matcher, val) ->
      if 'regexp' isnt TypeOf('matcher')
        matcher = new RegExp(matcher)
      matcher.test val

    ###*
    # $exists: key exists.
    ###

    $exists: (matcher, val) ->
      if matcher
        undefined isnt val
      else
        undefined is val

    ###*
    # $in: value in array.
    ###

    $in: (matcher, val) ->
      if 'array' isnt TypeOf(matcher)
        return false

      i = 0

      while i < matcher.length
        if Eql(matcher[i], val)
          return true
        i++
      false

    ###*
    # $nin: value not in array.
    ###

    $nin: (matcher, val) ->
      not @$in(matcher, val)

    ###*
    # @size: array length
    ###

    $size: (matcher, val) ->
      Array.isArray(val) and matcher is val.length
