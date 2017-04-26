###*
# toString ref.
###

toString = Object::toString

###*
# Return the type of `val`.
#
# @param {Mixed} val
# @return {String}
# @api public
###

module.exports = (val) ->
  switch toString.call(val)
    when '[object Function]'
      return 'function'
    when '[object Date]'
      return 'date'
    when '[object RegExp]'
      return 'regexp'
    when '[object Arguments]'
      return 'arguments'
    when '[object Array]'
      return 'array'
  if val is null
    return 'null'
  if val is undefined
    return 'undefined'
  if val is Object(val)
    return 'object'
  typeof val
