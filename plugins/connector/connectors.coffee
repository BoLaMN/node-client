module.exports = ->

  @factory 'Connectors', (Storage) ->

    class Connectors extends Storage
      @debug: true 
      
    new Connectors