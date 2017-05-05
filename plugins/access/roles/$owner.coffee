debug = require('debug')('security:acl')

module.exports = ->

  @decorator 'ACL', (ACL) ->

    ACL.OWNER = '$owner'

    ACL.registerResolver ACL.OWNER, (role, context, callback = ->) ->
      if !context or !context.model or !context.modelId
        return callback false

      modelClass = context.modelCtor
      modelId = context.modelId
      userId = context.getUserId()

      isOwner modelClass, modelId, userId, callback

      return

    isUserClass = (modelClass) ->
      if !modelClass
        return false

      User = modelClass.modelBuilder.models.User

      if !User
        return false

      modelClass == User or modelClass.prototype instanceof User

    matches = (id1, id2) ->
      if not id1? or id1 is '' or not id2? or id2 is ''
        return false

      id1 == id2 or id1.toString() == id2.toString()

    isOwner = (modelClass, modelId, userId, callback = ->) ->
      assert modelClass, 'Model class is required'

      debug 'isOwner(): %s %s userId: %s', modelClass and modelClass.modelName, modelId, userId

      if not userId
        return callback false

      if isUserClass modelClass
        return callback matches(modelId, userId)

      modelClass.findById modelId, (err, inst) ->

        processRelatedUser = (err, user) ->
          if !err and user
            debug 'User found: %j', user.id
            callback matches(user.id, userId)
          else
            callback false

          return

        if err or not inst
          debug 'Model not found for id %j', modelId
          return callback false

        debug 'Model found: %j', inst

        ownerId = inst.userId or inst.owner

        if ownerId and 'function' != typeof ownerId
          return callback matches(ownerId, userId)

        for r of modelClass.relations
          rel = modelClass.relations[r]

          if rel.type == 'belongsTo' and isUserClass(rel.modelTo)
            debug 'Checking relation %s to %s: %j', r, rel.modelTo.modelName, rel
            inst[r] processRelatedUser

            return

          debug 'No matching belongsTo relation found for model %j and user: %j', modelId, userId
          callback false

        return
      return

    ACL