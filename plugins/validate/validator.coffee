
module.exports = ->

  @factory 'Validator', (Type) ->
    
    class Validator extends Type

      @conform: (a, e, o) ->
        e a, o

      @format: ->

        if typeof value is 'string'
          formts = if Array.isArray(@format) then @format else [ @format ]
          valid = false

          i = 0
          l = formts.length

          while i < l
            format = formts[i].toLowerCase().trim()
            spec = formats[format]

            if not spec
              valid = false
              break

            i++

          if not valid
            return @error('format', property, value, errors)

      @enum: ->

        if value is null and Array.isArray(@type) and 'null' in @type
          # is allowed
        else if @type is 'array' and Array.isArray(value)
          for item in value when item not in @enum
            @error 'enum', property, value, errors
        else if value not in @enum
          @error 'enum', property, value, errors

      @dependacies: ->

        if typeof @dependencies is 'string' and object[@dependencies] is undefined
          @error 'dependencies', property, null, errors
        else if Array.isArray @dependencies 
          for dependacy in @dependencies when object[dependacy] is undefined
            @error 'dependencies', property, null, errors
        else if typeof @dependencies is 'object'
          @validateObject object, @dependencies, errors
