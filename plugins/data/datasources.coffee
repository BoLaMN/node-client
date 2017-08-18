module.exports = ->

  @factory 'Datasources', (Storage) ->

    class Datasources extends Storage
      @debug: true 

    new Datasources