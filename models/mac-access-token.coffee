module.exports = (Model) ->

  @getTokenFromRequest = (request) ->
    headerToken = request.headers.authorization

    if headerToken
      return @getTokenFromRequestHeader headerToken

    return

  ###*
  # Get the mac token from the request header.
  #
  # @see http://tools.ietf.org/html/rfc6750#section-2.1
  ###

  @getTokenFromRequestHeader = (header) ->
    if header.substring 0, 4 isnt 'MAC '
      return

    pairs = header.substring(4).trim().split(',')

    keyValues = {}

    for pair in pairs
      matches = pair.match /([a-zA-Z]*)="([\w=\/+]*)"/

      if matches.length isnt 3
        return

      [ key, value ] = matches

      keyValues[key.trim()] = value.trim()

    if keyValues.id is false or keyValues.ts is false or keyValues.nonce is false or keyValues.mac is false
      throw new InvalidRequestError 'MALFORMED'

    currentTimeStamp = Math.abs(keyValues.ts) - now()

    if currentTimeStamp > 300
      throw new InvalidRequestError 'EXPIRED'

    @findById keyValues.id
