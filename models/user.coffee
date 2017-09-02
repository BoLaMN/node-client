module.exports = (InvalidArgumentError, InvalidRequestError, debug) ->

  ###*
  # Retrieve the user from the model using a email/password combination.
  #
  # @see https://tools.ietf.org/html/rfc6749#section-4.3.2
  ###

  @login = (email, password) ->
    if not email
      throw new InvalidRequestError 'Missing parameter: `email`'

    if not validate.uchar email
      throw new InvalidRequestError 'Invalid parameter: `email`'

    if not password
      throw new InvalidRequestError 'Missing parameter: `password`'

    if not validate.uchar password
      throw new InvalidRequestError 'Invalid parameter: `password`'

    debug "in getUser (email: #{ email })"

    @findOne
      where: 
        email: email
      include: [ 
        { relation: 'groups', scope: { include: [ 'roles' ] } }, 
        'roles', 'applications' 
      ]
    .then (user) ->
      debug "in validatePassword (validating password for user: #{ JSON.stringify(user) })"

      user.hasPassword password
      
  ###*
  # Compare the given `password` with the users hashed password.
  #
  # @param {String} password The plain text password
  # @returns {Boolean}
  ###

  @::hasPassword = (plain) ->
    new Promise (resolve, reject) =>
      if not @password or not plain
        return reject new InvalidRequestError 'Invalid grant: user credentials are invalid'

      bcrypt.compare plain, @password, (err, match) ->
        if err or not match
          return reject new InvalidRequestError 'Invalid grant: user credentials are invalid'

        resolve()

