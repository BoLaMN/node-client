
module.exports = ->

  @factory 'Types', (Storage) ->

    class Types extends Storage
      @debug: true 
      
    new Types
