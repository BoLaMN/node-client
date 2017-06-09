'use strict'

module.exports = ->

  @factory 'Mixins', (Storage) ->

    class Mixins extends Storage
      @debug: true 
      
    new Mixins

  ###*
  # Apply named mixin to the model class
  # @param {Model} modelClass
  # @param {String} name
  # @param {Object} options
  ###

  @decorator 'Model', (Model, Mixins, injector, debug) ->

    Model.mixin = (name, options = {}) ->
      fn = Mixins[name]

      if typeof fn is 'function'
        return fn @, options

      model = injector.get name

      if model
        debug 'Mixin is resolved to a model: %s', name
        @mixin model, options
      else
        throw new Error 'Model "' + @name + '" uses unknown mixin: ' + name

      return

    Model
