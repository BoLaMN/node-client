module.exports = ->

  @factory 'Adapters', (Storage) ->

    class Adapters extends Storage
      @debug: true 
      
    new Adapters