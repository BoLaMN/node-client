module.exports = (app) ->

  @provider 'config', (isEmpty, inflector, injector, merge, path, glob, env, debug) ->
    { dasheize, underscore, camelize } = inflector

    directories = app.directories.map (directory) ->
      path.join directory, 'server'

    addWithSuffixes = (list, base, suffixes...) ->
      add = (element) ->
        if list.indexOf(element) == -1
          list.push element

      not isEmpty(base) and add(base)

      add base + '.local'

      suffixes.forEach (suffix) =>
        if not isEmpty suffix
          base += (if base then '.' else '') + suffix

          add base

    build = (list) ->
      files = []

      parsers = injector.get 'parsers'

      node = env['NODE_ENV'] or 'dev'
      node_app = env['NODE_APP_INSTANCE']
      
      list.forEach (base) =>
        base = parsers.tokens(base) or base

        addWithSuffixes files, base, node_app
        addWithSuffixes files, base, node, node_app

      files

    get = (dirs = directories, configs, fn) ->
      if typeof configs is 'function'
        return get directories, dirs, configs

      if not Array.isArray dirs 
        dirs = [ dirs ]

      parsers = injector.get 'parsers'
      
      names = configs.join ',' 
      exts = parsers.exts.join ',.'

      if configs.length > 1
        names = '{' + names + '}'

      pattern = names + '{.' + exts + '}'
    
      for dir in dirs
        ptrn = path.resolve path.join dir, pattern
        files = glob.sync ptrn

        for file in files
          fn file, require file 

      return

    one = (file, dirs = directories) ->
      name = path.basename file
      base = name.split('.')[0] 

      data = load [ file ], dirs

      data[base]

    load = (list, dirs = directories) ->
      if not Array.isArray dirs 
        dirs = [ dirs ]

      result = {}

      files = build list

      get dirs, files, (file, config) =>
        name = path.basename file
        base = name.split('.')[0] 

        result[base] ?= {}
        result[base].definition = merge result[base].definition or {}, config

      result

    from = (list, dirs) ->
      result = {}

      if Array.isArray list
        files = list
      else
        files = Object.keys list 

        files.forEach (file) ->
          orig = file.toLowerCase()

          dash = dasheize file 

          if dash isnt orig
            list[dash] = list[file]
            files.push dash

          under = underscore file 

          if under isnt orig
            list[under] = list[file]
            files.push under

      get dirs, files, (file, config) =>
        ext = path.extname file
        name = path.basename file, ext
        base = camelize name.split('.')[0] 

        result[base] ?= {}
        result[base].name = base 

        orig = files.find (orig) ->
          norm = path.normalize orig 
          file.search(norm) > -1

        #debug 'config:original', files, file, orig

        result[base].config = list[orig] or {}

        if typeof config is 'function'
          result[base].fn = config
        else 
          result[base].definition = merge result[base].definition or {}, config

      result
    
    @$get = -> 
    
      { definition } = one 'config'

      definition.get = get
      definition.load = load
      definition.one = one
      definition.build = build 
      definition.from = from 

      definition
