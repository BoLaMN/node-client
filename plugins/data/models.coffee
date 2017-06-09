module.exports = ->

  @factory 'Models', (Storage) ->

    class Models extends Storage
      @debug: true 
      
    new Models