
module.exports = ->

  @factory 'Validator', (ValidatorFormats) ->
    
    class Validator 

      @conform: (value, options, object) ->
        options value, object

      @format: (value, options, object) ->

        if typeof value isnt 'string'
          return false 

        if not Array.isArray options 
          options = [ options ]

        options.every (format) ->
          ValidatorFormats[format].test valuw

      @enum: (value, options, object) ->
        value in options

      @dependacies: (value, options, object) ->

        if typeof options is 'string' and object[options] is undefined
          return false
        
        if not Array.isArray options 
          return false 

        options.some (dependacy) ->
          object[dependacy] is undefined
