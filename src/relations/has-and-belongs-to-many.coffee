HasMany = require './has-many'

class HasAndBelongsToMany extends HasMany

  @initialize: (args...) ->
    super

    [ @from, @to, params ] = args

    if not @through
      if @polymorphic
        throw new Error "{{Polymorphic}} relations need a through model"

      if @throughModel
        @through = @throughModel
      else
        name1 = @from.modelName + @to.modelName
        name2 = @to.modelName + @from.modelName

        @through = @from.models.$get(name1) or @from.models.$get(name2)

        if not @through
          @through = @to.define name1

    if @through
      @through.belongsTo @to.modelName

    @

  constructor: (instance) ->
    super

    @instance = instance

module.exports = HasAndBelongsToMany