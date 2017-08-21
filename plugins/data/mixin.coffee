'use strict'

module.exports = ->

  @factory 'ModelMixin', (Mixins) ->

    class ModelMixin

      @mixin: (name, options = {}) ->

        Mixins.get name, (mixin) =>
          if typeof mixin is 'function'
            return mixin @, options
          else
            throw new Error 'Model "' + @name + '" uses unknown mixin: ' + name

        return
 