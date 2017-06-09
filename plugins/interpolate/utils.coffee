module.exports = ->

  @factory 'InterpolateUtils', (injector) ->

    globals = /\b(this|Array|Date|Object|Math|JSON)\b/g

    isName = (char) ->
      not /\s|,|:|=|"|'|\[|\{|\]|\}|#/.test(char)

    isWS = (char) ->
      /\s/.test char

    isCRLF = (char, nextChar) ->
      char is '\r' and nextChar is '\n'

    isNameSeparator = (char) ->
      char in [ ':', '=' ]

    isEndOfDQuote = (prevChar, char) ->
      prevChar isnt '\\' and char is '"'

    isEndOfSQuote = (prevChar, char) ->
      prevChar isnt '\\' and char is '\''

    isBeginOfBracket = (char) ->
      char in [ '[', '{' ]

    isEndOfBracket = (char) ->
      char in [ ']', '}' ]

    isBracket = (char) ->
      isBeginOfBracket(char) or isEndOfBracket(char)

    stringToLiteral = (str) ->
      str
        .replace /([-()[\]{}+?*.$^|,:#<!\\])/g, '\\$1'
        .replace /\x08/g, '\\x08'

    tokenize = (text) ->
      tokens = []
     
      i = 0

      while i < text.length
        currentChar = text.charAt i

        prevChar = text.charAt i - 1
        nextChar = text.charAt i + 1
        
        if isBracket currentChar
          tokens.push currentChar
        else if currentChar in [ ',', '\n' ]
          ++i
          continue
        else if isCRLF currentChar, nextChar
          ++i
        else if isNameSeparator currentChar
          tokens.push ':'
        else if currentChar in [ '"', '\'' ]
          buffer = ''
          isSQuote = currentChar is '\''

          escapeCount = 0

          currentChar = text.charAt ++i
          prevChar = text.charAt i - 1
          
          while not (if isSQuote then isEndOfSQuote(prevChar, currentChar) else isEndOfDQuote(prevChar, currentChar)) and i < text.length
            if isSQuote and currentChar is '"' and escapeCount % 2 is 0
              buffer += '\\'
            
            buffer += currentChar
            escapeCount = if currentChar is '\\' then escapeCount + 1 else 0
            
            currentChar = text.charAt ++i
            prevChar = text.charAt i - 1

          tokens.push '"' + buffer + '"'

        else if currentChar is '|'
          buffer = ''

          verbatimBuffer = []
          verbatimExit = false

          while i < text.length
            currentChar = text.charAt ++i
            nextChar = text.charAt i + 1

            if verbatimExit
              if currentChar is '|'
                verbatimExit = false
                ++i
                continue
              else if isCRLF currentChar, nextChar
                ++i
                break
              else if currentChar is '\n'
                break
              else if not isWS currentChar
                --i
                break
            else if isCRLF currentChar, nextChar
              ++i
              verbatimBuffer.push stringToLiteral buffer
              buffer = ''
              verbatimExit = true
            else if currentChar is '\n'
              verbatimBuffer.push stringToLiteral buffer
              buffer = ''
              verbatimExit = true
            else
              buffer += currentChar

          if not verbatimExit
            verbatimBuffer.push stringToLiteral buffer

          buffer = ''
          tokens.push '"' + verbatimBuffer.join('\\n') + '"'
        else if currentChar is '#'
          while i < text.length
            currentChar = text.charAt ++i
            nextChar = text.charAt i + 1
            
            if currentChar is '\n'
              break
            else if isCRLF currentChar, nextChar
              ++i
              break
        else if isWS currentChar
          while isWS(currentChar) and i < text.length
            currentChar = text.charAt ++i
          --i
        else
          if not isName nextChar
            tokens.push currentChar
            ++i
            continue

          buffer = currentChar

          while i < text.length
            currentChar = text.charAt ++i
            nextChar = text.charAt i + 1
            buffer += currentChar

            if not isName nextChar
              break

          tokens.push buffer

        ++i

      tokens

    prop = (str) ->
      str
        .replace(/\.\w+|\w+ *\(|"[^"]*"|'[^']*'|\/([^/]+)\//g, '')
        .replace(globals, '')
        .match(/[$a-zA-Z_]\w*/g) or []

    map = (str, props, fn) ->
      re = /\.\w+|\w+ *\(|"[^"]*"|'[^']*'|\/([^/]+)\/|[a-zA-Z_]\w*/g

      str.replace re, (_) ->
        if '(' == _[_.length - 1]
          return fn(_)

        if ! ~props.indexOf(_)
          return _

        fn _

    unique = (arr) ->
      ret = []
      i = 0

      while i < arr.length
        if ~ret.indexOf(arr[i])
          i++
          continue

        ret.push arr[i]
        i++

      ret

    prefixed = (str) ->
      (_) -> str + _

    parse: (str, scope, context) ->
      regex = RegExp ' *\\| *'
      re = RegExp """{([^"|]*)}|"([^"|:]*)"|'([^'|]*)'|([^ \t(,|:)]+)""", 'g'

      expression = injector.get 'InterpolateExpression'

      str.split(regex).map (call) ->
        parts = call.match re
        
        name = parts.shift()

        compiled = parts
          .map (expr) ->
            fn = new expression expr

            try
              val = fn.exec scope, context
            catch e
              console.error expr, e.message
              val = expr

            val

        name: name
        args: compiled

    props: (str, fn) ->
      p = unique(prop(str))

      if fn and 'string' == typeof fn
        fn = prefixed(fn)

      if fn
        return map(str, p, fn)

      p

    unique: unique

    cson: (text) ->
      if not isBracket text
        return text 

      tokens = tokenize String text

      if not isBeginOfBracket(tokens[0]) and tokens[1] isnt undefined
        if tokens[1] is ':'
          tokens.unshift '{'
          tokens.push '}'
        else
          tokens.unshift '['
          tokens.push ']'

      i = 0

      while i < tokens.length
        token = tokens[i]
        nextToken = tokens[i + 1]

        if isName(token.charAt()) and tokens[i + 1] is ':'
          tokens[i] = '"' + tokens[i] + '"'

        isOpenBracket = /\[|\{|:/.test tokens[i].charAt()

        if nextToken
          isCloseBracket = /\]|\}|:/.test nextToken.charAt()

        if not isOpenBracket and not isCloseBracket
          tokens[i] += ','

        ++i
      
      try 
        JSON.parse tokens.join ''
      catch 
        text