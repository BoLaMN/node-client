getArgs = require './utils/get-args'
assert = require './utils/assert'

ObjectProxy = require './utils/proxy'

module.exports = ->

  @factory 'SharedModel', (PersistedModel, api, Utils) ->

    setupRemoteMethods = (model) ->
      route = api.section model.modelName

      console.log route

    class SharedModel extends PersistedModel

      @configure: (@modelName, attributes) ->
        super

        setupRemoteMethods @

        @

      @remoteMethod: (name, { method, path, params }) ->
        route = api.section @modelName
        fn = Utils.getDeepProperty @, name

        route[method] path, { params }, fn