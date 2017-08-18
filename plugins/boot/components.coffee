module.exports = ->

  @provider 'components', ->
    configs = {}

    @$get = (config) ->
      { definition } = config.one 'component-config'

      configs = config.from definition
      configs

  @run (components, debug) ->

    Object.keys(components).forEach (key) ->
      component = components[key]
      component.fn component.definition

      debug 'components:' + key, component 

    return

