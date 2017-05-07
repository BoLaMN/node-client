module.exports = ->

  @decorator 'Utils', (Utils) ->

    Utils.buildOptions = (instance, name, index) ->
      if arguments.length is 2
        index = name
        { name, instance } = instance

      if not instance?.$options
        return

      obj = Utils.clone instance.$options
      obj.name = name

      if index isnt undefined
        obj.index = index

      obj.root = instance.$parent or undefined
      obj.parent = instance
      obj

    Utils