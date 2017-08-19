module.exports = ->

  @provider 'middlewares', ->
    configs = {}
    
    @$get = (config) ->
      { definition } = config.one 'middleware'

      configs = definition
      configs

  @run (middlewares, debug, config, api) ->
    phases = Object.keys middlewares 

    phases.forEach (phase) ->
      middleware = config.from middlewares[phase]
      
      debug 'middlewares:' + phase, middleware 

      api.use phase, middleware.fn 

    return 

