module.exports = ->

  @groupByName = (instance) ->
    roles = []

    if instance.roles
      instance.roles.forEach (role) ->
        role.push role.name

    if instance.groups
      instance.groups.forEach (group) ->
        return unless group.roles

        instance.roles.forEach (role) ->
          roles.push role.name

    roles 
