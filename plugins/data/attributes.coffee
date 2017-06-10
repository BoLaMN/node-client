module.exports = ->

  @factory 'Attributes', (Storage) ->

    class Attributes extends Storage
      @debug: true 
      
      validate: (object) ->

        validate = (key, cb) =>
          @[key].validator object, cb

        @$each @keys, validate, next
