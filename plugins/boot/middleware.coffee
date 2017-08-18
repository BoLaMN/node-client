module.exports = ->

  @provider 'middlewares', ->
    configs = {}
    
    # app.defineMiddlewarePhases phases 
    # app.middlewareFromConfig config.fn, config 

    @$get = (config) ->
      { definition } = config.one 'middleware'

      configs = definition
      configs

  @run (middlewares, debug) ->
    phases = Object.keys middlewares 

    phases.forEach (key) ->
      middleware = middlewares[key]

      Object.keys(middleware).forEach (name) ->
        value = middleware[name]
        
        debug 'middlewares:' + name, value 

    return 

