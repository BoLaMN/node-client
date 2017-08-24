module.exports = ->

  @provider 'middlewares', ->
    configs = {}
    
    @$get = (config) ->
      { definition } = config.one 'middleware'

      configs = definition
      configs

  @run (middlewares, debug, config, api, injector) ->
    phases = Object.keys middlewares 

    phases.forEach (phase) ->
      middleware = config.from middlewares[phase]
      modules = Object.keys middleware

      debug 'middlewares:' + phase, middleware 

      modules.forEach (name) ->
        mod = middleware[name]
        
        return unless mod.fn 

        args = injector.inject injector.parse(mod.fn), name, false
        args = args.filter (arg) -> arg?
        args.push mod.config

        debug 'middlewares:inject', mod, args

        fn = mod.fn.apply null, args

        if phase is 'error'
          api.error fn
        else
          api.use phase, fn

    return 

