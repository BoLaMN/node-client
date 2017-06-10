'use strict'

module.exports = ->

  @factory 'Mixins', (Storage) ->

    class Mixins extends Storage
      @debug: true 
      
    new Mixins
