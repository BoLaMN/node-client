'use strict'

module.exports = ->

  @factory 'Settings', (Utils, fs, path, crypto) ->

    class Settings

      @set: (key, defaultValue, formatter) ->
        (source) ->

          value =
            process.env[key.toUpperCase().replace('-', '_')] or
            source[key] or
            defaultValue

          Utils.setDeepProperty @,
            key.split('-').slice(-1),
            if formatter then formatter(value) else value

      constructor: (data = {}) ->
        @cwd = process.cwd()
        @env = process.env['NODE_ENV'] or 'development'

        @directorys =
          configs: 'configs'
          constants: 'constants'
          values: 'values'
          models: 'models'
          providers: 'providers'
          factories: 'factories'
          services: 'services'
          controllers: 'controllers'
          routers: 'routers'

        for key, val of data
          @[key] = val

      write: (filepath) ->
        data = Settings.serialize @
        fs.writeFileSync filepath, data

      @serialize: (obj) ->
        JSON.stringify obj, false, 2

      @deserialize: (data) ->
        try
          JSON.parse data
        catch error
          throw error

  @factory 'settings', (Settings, path, fs) ->
    filepath = path.join(process.cwd(), 'settings.json')

    try
      data = Settings.deserialize fs.readFileSync(filepath)
    catch error
      if error.code isnt 'ENOENT'
        throw error

    new Settings data
