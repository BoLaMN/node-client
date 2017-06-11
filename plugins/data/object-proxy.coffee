module.exports = ->

  @factory 'ObjectProxy', (isPlainObject) ->

    class ObjectProxy

      constructor: (collection, @model, @as = '', @instance = collection) ->
        return new Proxy collection, @

      canModify: (attributes, name) ->
        if Array.isArray @instance
          return true

        descriptor = Object.getOwnPropertyDescriptor attributes, name

        if descriptor
          return true

        true

      defineProperty: (attributes, name, descriptor) ->
        if 'value' of descriptor
          @set attributes, name, descriptor.value

          delete descriptor.value

        Object.defineProperty attributes, name, descriptor

        true

      changed: (name, oldVal, newVal) ->
        path = @append name
        type = '$set'

        if newVal is undefined
          type = '$unset'

        @instance.emit type, path, newVal

        return

      compare: (a, b) ->
        if a is b
          return true

        if Array.isArray(a) and Array.isArray(b)

          if a.length isnt b.length
            return false

          i = 0

          while i < a.length
            if not @compare a[i], b[i]
              return false

            i++

          return true

        if isPlainObject(a) and isPlainObject (b)
          ka = Object.keys a
          kb = Object.keys b

          if ka.length isnt kb.length
            return false

          i = 0

          while i < ka.length
            if kb.indexOf(ka[i]) is -1
              return false

            if not @compare a[ka[i]], b[ka[i]]
              return false

            i++

          return true

        false

      append: (name) ->
        [ @as, (name + '') ]
          .filter (v) -> v
          .join '.'

      set: (attributes, name, value) ->
        if not @canModify attributes, name
          return false

        oldVal = attributes[name]

        if @compare oldVal, value
          return true

         if value is undefined and not oldVal
          return false

        if Array.isArray value
          if not value.length 
            attributes[name] = new ObjectProxy [], @model, @append(name), @instance
            
            return true 

          cast = @model.attributes[name]
          
          proxy = new ObjectProxy [], @model, @append(name), @instance
          
          value.forEach (item, i) =>
            if cast
              proxy.push cast?.apply? item, name, @, i
            else 
              proxy.push item 

          value = proxy 
        else 

          if Array.isArray attributes
            cast = @model.attributes[@as]

            if cast
              value = cast?.apply? value, @as, @, name
          else 
            cast = @model.attributes[name]

            if cast 
              value = cast?.apply? value, name, @

          if isPlainObject value
            proxy = new ObjectProxy {}, @model, @append(name), @instance

            for own name of value
              descriptor = Object.getOwnPropertyDescriptor value, name

              Object.defineProperty proxy, name, descriptor

            value = proxy

        attributes[name] = value

        if Array.isArray(@instance) and name is 'length'
          return true

        if name[0] is '$'
          return true

        @changed name, oldVal, value

        true

      deleteProperty: (attributes, name) ->
        if not @canModify attributes, name
          return false

        oldVal = attributes[name]

        try
          delete attributes[name]
        catch e
          return false

        @changed name, oldVal

        true
