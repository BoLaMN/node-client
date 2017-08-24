
module.exports = (AccessHandler, opts = {}) ->

  (req, res) ->
    AccessHandler.check req, res 


