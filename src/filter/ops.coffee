###*
# Module dependencies.
###

eql = require './eql'
type = require './type'

###*
# $ne: not equal.
###

exports.$ne = (matcher, val) ->
  not eql(matcher, val)

###*
# $gt: greater than.
###

exports.$gt = (matcher, val) ->
  type(matcher) is 'number' and val > matcher

###*
# $gte: greater than equal.
###

exports.$gte = (matcher, val) ->
  type(matcher) is 'number' and val >= matcher

###*
# $lt: less than.
###

exports.$lt = (matcher, val) ->
  type(matcher) is 'number' and val < matcher

###*
# $lte: less than equal.
###

exports.$lte = (matcher, val) ->
  type(matcher) is 'number' and val <= matcher

###*
# $regex: supply a regular expression as a string.
###

exports.$regex = (matcher, val) ->
  if 'regexp' isnt type('matcher')
    matcher = new RegExp(matcher)
  matcher.test val

###*
# $exists: key exists.
###

exports.$exists = (matcher, val) ->
  if matcher
    undefined isnt val
  else
    undefined is val

###*
# $in: value in array.
###

exports.$in = (matcher, val) ->
  if 'array' isnt type(matcher)
    return false

  i = 0

  while i < matcher.length
    if eql(matcher[i], val)
      return true
    i++
  false

###*
# $nin: value not in array.
###

exports.$nin = (matcher, val) ->
  not exports.$in(matcher, val)

###*
# @size: array length
###

exports.$size = (matcher, val) ->
  Array.isArray(val) and matcher is val.length
