
module.exports = (opts = {}) ->

  (err, req, res) ->
    { code, statusCode } = err

    console.log err
    
    res.json err, {}, code or statusCode or 500

    return
