module.exports = (Model) ->

  ###*
  # Retrieve the user from the model using a email/password combination.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.3.2
  ###

  @handleGrant = (request, response) ->
    if !request
      throw new InvalidArgumentError 'REQUEST'

    { email, password } = @validateInputParams request

    debug "in getUser (email: #{ email })"

    query =
      where: { email }
      include: [ 'roles', 'applications' ]

    @findOne query
      .then (user) ->
        debug "in validatePassword (user: #{ JSON.stringify user })"
        
        user.hasPassword password

  @validateInputParams = (request) ->
    { email, password } = request.body

    if not email
      throw new InvalidRequestError 'Missing parameter: `email`'

    if not validate.uchar email
      throw new InvalidRequestError 'Invalid parameter: `email`'

    if not password
      throw new InvalidRequestError 'Missing parameter: `password`'

    if not validate.uchar password
      throw new InvalidRequestError 'Invalid parameter: `password`'

    { email, password }
