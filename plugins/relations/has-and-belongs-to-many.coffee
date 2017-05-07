module.exports = ->

  @factory 'HasAndBelongsToMany', (HasMany, Models, Model) ->

    class HasAndBelongsToMany extends HasMany

      @initialize: (@from, @to, params) ->
        super

        if not @through
          if @polymorphic
            throw new Error "{{Polymorphic}} relations need a through model"

          if @throughModel
            @through = @throughModel
          else
            name1 = @from.modelName + @to.modelName
            name2 = @to.modelName + @from.modelName

            @through = Models.$get(name1) or Models.$get(name2)

            if not @through
              @through = Model.define name1

        if @through
          @through.belongsTo @to.modelName

        @

      constructor: (@instance) ->
        super
