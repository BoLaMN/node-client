module.exports = ->

  @decorator 'utils', (utils) ->

    utils.glob2re = (pat) ->
      n = 1

      tr = (pat) ->
        pat.replace /\W/g, (m0) ->
          if m0 is '?' then '[\\s\\S]' else '\\' + m0

      pat = pat.replace /\W[^*]*/g, (m0, mp, ms) ->
        if m0.charAt(0) isnt '*'
          return tr m0

        eos = if mp + m0.length is ms.length then '$' else ''

        '(?=([\\s\\S]*?' + tr(m0.substr(1)) + eos + '))\\' + n++
      
      new RegExp '^' + pat + '$'

    utils