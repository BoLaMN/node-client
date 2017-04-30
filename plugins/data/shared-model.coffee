getArgs = require './utils/get-args'
assert = require './utils/assert'
routes = require './routes'
{ inspect } = require 'util'

ObjectProxy = require './utils/proxy'

module.exports = ->

  @factory 'SharedModel', (PersistedModel, api, Utils) ->

    class SharedModel extends PersistedModel

      @configure: (@modelName, attributes) ->
        super

        for name, config of routes
          @remoteMethod name, config

        console.log inspect(api.toObject(), false, null)

        @

      @remoteMethod: (name, { method, path, params, description, accessType }) ->
        route = api.section @modelName
        fn = Utils.getDeepProperty @, name

        route[method] name, path, { params, description, accessType }, fn