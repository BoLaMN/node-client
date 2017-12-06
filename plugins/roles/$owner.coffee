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
      if not userId
        return callback false

      if isUserClass modelClass
        return callback matches(modelId, userId)

      modelClass.findById modelId, (err, inst) ->

        processRelatedUser = (err, user) ->
          if !err and user
            callback matches(user.id, userId)
          else
            callback false

          return

        if err or not inst
          return callback false

        ownerId = inst.userId or inst.owner

        if ownerId and 'function' != typeof ownerId
          return callback matches(ownerId, userId)

        for r of modelClass.relations
          rel = modelClass.relations[r]

          if rel.type == 'belongsTo' and isUserClass(rel.modelTo)
            inst[r] processRelatedUser

            return

          callback false

        return
      return

    ACL