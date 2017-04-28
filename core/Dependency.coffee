'use strict'

ARROW_ARG = /^([^\(]+?)=>/
FN_ARGS = /^[^\(]*\(\s*([^\)]*)\)/m
FN_ARG_SPLIT = /,/
FN_ARG = /^\s*(_?)(\S+?)\1\s*$/
STRIP_COMMENTS = /((\/\/.*$)|(\/\*[\s\S]*?\*\/))/mg

class Dependency
  constructor: (dependacy) ->
    for own key, val of dependacy
      @[key] = val

    @dependencies = @extractDependencies()

  extractDependencies: ->
    str = @fn.toString().replace STRIP_COMMENTS, ''

    match = str.match(ARROW_ARG) or str.match(FN_ARGS)
    args = match[1].split(FN_ARG_SPLIT)

    args.map (str) ->
      str.trim()

module.exports = Dependency
