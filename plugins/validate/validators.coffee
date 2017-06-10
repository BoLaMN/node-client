
module.exports = ->

  @factory 'Validators', (Storage) ->

    class Validators extends Storage
      @debug: true 
      
    new Validators
