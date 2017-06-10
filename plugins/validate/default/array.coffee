 
module.exports = ->

  @validator 'Array', (Validator) ->
    
    class Array extends Validator

      @items: (a, e) ->
        i = 0
        l = a.length

        while i < l
          nestedErrors = []
          @validateProperty object, a[i], property, e, nestedErrors

          nestedErrors.forEach (err) ->
            if Array.isArray(e) and err.property == property
              err.property = (if property then property + '.' else '') + i
            else
              err.property = (if property then property + '.' else '') + i + (if err.property then '.' + err.property.replace(property + '.', '') else '')

            return

          nestedErrors.unshift errors.length, 0

          Array::splice.apply errors, nestedErrors

          i++

        true

      @minItems: (a, e) ->
        a.length >= e

      @maxItems: (a, e) ->
        a.length <= e

      @uniqueItems: (a, e) ->
        if !e
          return true

        h = {}

        i = 0
        l = a.length

        while i < l
          key = JSON.stringify(a[i])

          if h[key]
            return false

          h[key] = true

          i++

        true