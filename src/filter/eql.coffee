###*
# Module dependencies.
###

type = require './type'

###*
# Module exports.
###

###*
# MongoDB style value comparisons.
#
# @param {Object} matcher
# @param {Object} value
# @return {Boolean} true if they match
###

eql = (matcher, val) ->
  switch type(matcher)
    when 'null', 'undefined'
      return null is val
    when 'regexp'
      return matcher.test(val)
    when 'array'
      if 'array' is type(val) and matcher.length is val.length
        i = 0

        while i < matcher.length
          if not eql(val[i], matcher[i])
            return false
          i++

        return true
      else
        return false
    when 'object'
      keys = {}

      for i of matcher
        if matcher.hasOwnProperty(i)
          if not val.hasOwnProperty(i) or not eql(matcher[i], val[i])
            return false

        keys[i] = true

      for i of val
        if val.hasOwnProperty(i) and not keys.hasOwnProperty(i)
          return false
      return true
    else
      return matcher is val

  return

module.exports = eql
