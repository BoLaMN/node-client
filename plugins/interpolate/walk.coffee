module.exports = ->

  @factory 'InterpolateWalk', (isString, isPlainObject) ->
      
    walkObject = (object, handler) ->
      result = {}

      for own key, value of object
        newKey = walk key, handler

        if newKey.length
          result = walk value, handler
          result[newKey] = walk result, handler

      result

    walkArray = (array, handler) ->
      array.map (input) ->
        walk input, handler

    walk = (input, handler) ->
      if not input
        return input

      if Array.isArray input
        walkArray input, handler
      else if isPlainObject input
         walkObject input, handler
      else if isString input
        handler input
      else
        input

    walk