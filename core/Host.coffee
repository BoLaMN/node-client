'use strict'

injector = require './injectorInstance'

Registry = require './Registry'

class Host

  constructor: ->
    @registry = new Registry()

  @bootstrap: ->
    host = new Host

    host.registry
      .glob()
      .require()
      .resolve()
      .prioritize()
      .initialize()

    host

  run: ->
    @injector = injector
    @injector.get 'main'

    @injector
      .filter type: 'config'
      .start()

    @injector
      .filter type: 'run'
      .start()

    @registry.start()
    @

module.exports = Host
