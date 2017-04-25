clone = require '../utils/clone'

options = (instance, name, index) ->
  obj = clone instance.$options
  obj.name = name
  if index isnt undefined
    obj.index = index
  obj.root = instance.$parent or undefined
  obj.parent = instance
  obj

module.exports = options