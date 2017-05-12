module.exports = ->

  @decorator 'Utils', (Utils, merge) ->

    Utils.mergeQuery = (base = {}, update, spec = {}) ->
      if not update
        return

      if update.where and Object.keys(update.where).length > 0
        if base.where and Object.keys(base.where).length > 0
          base.where = and: [
            base.where
            update.where
          ]
        else
          base.where = update.where

      if spec.include isnt false and update.include
        if !base.include
          base.include = update.include
        else
          if spec.nestedInclude is true
            saved = base.include
            base.include = {}
            base.include[update.include] = saved
          else
            base.include = merge base.include, update.include

      if spec.fields isnt false and update.fields isnt undefined
        base.fields = update.fields
      else if update.fields isnt undefined
        base.fields = [].concat base.fields, update.fields

      if (!base.order or spec.order is false) and update.order
        base.order = update.order

      if spec.limit isnt false and update.limit isnt undefined
        base.limit = update.limit

      skip = spec.skip isnt false and spec.offset isnt false

      if skip and update.skip isnt undefined
        base.skip = update.skip

      if skip and update.offset isnt undefined
        base.offset = update.offset

      base

    Utils