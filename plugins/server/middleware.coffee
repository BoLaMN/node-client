'use strict'

module.exports = ->

  @factory 'Middleware', (HttpError) ->

    jsonWriter: ->
      (req, res, next) ->
        if res.json
          return next()

        res.json = (json, headers, code) ->
          try
            data = JSON.stringify(json)
          catch e
            console.error e
            return next new HttpError.InternalServerError 'Could not stringify JSON'

          if req.parsedUrl and req.parsedUrl.query.jsonp
            data = req.parsedUrl.query.jsonp + '(' + data + ')'

          headers = headers or {}
          headers['Content-Type'] = 'application/json'

          res.writeHead code or 200, headers
          res.end data

        next()

    describeApi: (root) ->
      (req, res, next) ->
        res.json root.describe()
