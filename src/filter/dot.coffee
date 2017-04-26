###*
# Module dependencies.
###

type = require './type'

###*
# Gets a certain `path` from the `obj`.
#
# @param {Object} target
# @param {String} key
# @return {Object} found object, or `undefined
# @api public
###

parent = (obj, key, init) ->
  if ~key.indexOf('.')
    pieces = key.split('.')
    ret = obj

    i = 0

    while i < pieces.length - 1
      if Number(pieces[i]) is pieces[i] and 'array' is type(ret)
        ret = ret[pieces[i]]
      else if 'object' is type(ret)
        if init and not ret.hasOwnProperty(pieces[i])
          ret[pieces[i]] = {}
        if ret
          ret = ret[pieces[i]]

      i++
    ret
  else
    obj

exports.get = (obj, path) ->
  if ~path.indexOf('.')
    par = parent(obj, path)
    mainKey = path.split('.').pop()

    t = type(par)

    if 'object' is t or 'array' is t
      return par[mainKey]
  else
    return obj[path]

  return

###*
# Sets the given `path` to `val` in `obj`.
#
# @param {Object} target
# @Param {String} key
# @param {Object} value
# @api public
###

exports.set = (obj, path, val) ->
  if ~path.indexOf('.')
    par = parent(obj, path, true)
    mainKey = path.split('.').pop()

    if par and 'object' is type(par)
      par[mainKey] = val
  else
    obj[path] = val

  return

###*
# Gets the parent object for a given key (dot notation aware).
#
# - If a parent object doesn't exist, it's initialized.
# - Array index lookup is supported
#
# @param {Object} target object
# @param {String} key
# @param {Boolean} true if it should initialize the path
# @api public
###

exports.parent = parent
