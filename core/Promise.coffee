throttle = (concurrency, fn) ->
  throw new Error "Concurrency must be equal or higher than 1." unless concurrency >= 1
  throw new Error "Worker must be a function." unless typeof fn is "function"

  numRunning = 0

  queue = []

  startJobs = ->
    startJob job while numRunning < concurrency and job = queue.shift()

  startJob = (job) ->
    rejectedHandler = makeRejectedHandler(job)

    numRunning++

    promise = fn.apply job.context, job.arguments
    promise.then makeFulfilledHandler(job), rejectedHandler

  makeFulfilledHandler = (job) ->
    (result) ->
      numRunning--
      job.resolve result

      startJobs() if queue.length

  makeRejectedHandler = (job) ->
    (error) ->
      numRunning--
      job.reject error

      startJobs() if queue.length

  (args...) ->
    new Promise (resolve, reject) ->
      queue.push
        context: this
        arguments: args
        resolve: resolve
        reject: reject

      startJobs()

doBatch = (map, fns) ->
  if Array.isArray fns
    doBatchArray map, fns
  else
    doBatchObject map, fns

doBatchArray = (map, fns) ->
  map fns, (fn) -> fn()

doBatchObject = (map, obj) ->
  keys = Object.keys obj
  fns = (val for key, val of obj)

  map fns, (fn) -> fn()
    .then (res) ->
      outputs = {}
      outputs[keys[i]] = result for result, i in res
      outputs

noop = ->

asCallback = (cb = noop, options = {}) ->
  if typeof cb isnt 'function'
    return throw new Error "callback needs to be a function"

  success = (data) ->
    if options.spread and Array.isArray data
      cb.apply null, [ null ].concat data
    else
      cb null, data
    data

  error = (err) ->
    cb err
    err

  @then success, error

  @

tap = (handler) ->

  @then (v) ->
    Promise.resolve handler(v)
    v

Promise::asCallback ?= asCallback
Promise::tap ?= tap

Promise.each = (vals, iterator, { concurrency, handle, fail, stopEarly, finish } = {}) ->
  new Promise (resolve, reject) ->
    return resolve finish?() unless vals.length

    concurrency ?= 1024
    throttled = throttle concurrency, iterator

    try
      promises = (throttled val for val in vals)
    catch error
      return reject error

    stopped = false
    remaining = promises.length

    rejector = (index) ->
      (err) ->
        if not fail 
          stopped = true
          reject err 
        else
          fail? err, index 

    resolver = (index) ->
      return (val) ->
        return if stopped

        try handle? val, index
        catch error
          return rejector(index)(error)

        remaining--

        if remaining is 0 or stopEarly?()
          stopped = true
          resolve finish?()

    for promise, i in promises
      try promise.then resolver(i), rejector(i)
      catch error
        rejector(i)(error)

    return

Promise.eachLimit = (vals, concurrency, iterator, options = {}) ->
  options.concurrency = concurrency
  Promise.each vals, iterator, options

Promise.eachSeries = (vals, iterator, options = {}) ->
  new Promise (resolve, reject) ->
    i = 0

    resolver = (j) ->
      (result) ->
        options.handle? result, j
        iterate()

    iterate = ->
      if (i >= vals.length) or options.stopEarly?()
        resolve options.finish?()
      else
        try
          promise = iterator vals[i]
        catch err
          return reject err

        try
          promise.then resolver(i)
            .then null
            .catch reject
        catch error
          reject error

        i++

    iterate()

Promise.series = (fns) ->
  doBatch Promise.mapSeries, fns

Promise.parallel = (fns) ->
  doBatch Promise.map, fns

Promise.parallelLimit = (fns, concurrency) ->
  mapLimit = Promise.mapLimit

  makeMapFn = (concurrency) ->
    (fns, iterator) ->
      mapLimit fns, concurrency, iterator

  doBatch makeMapFn(concurrency), fns

Promise.concat = (vals, iterator) ->
  res = []

  Promise.each vals, iterator,
    handle: (val) -> res = res.concat val
    finish: -> res

Promise.concatSeries = (inputs, iterator) ->
  res = []

  Promise.eachSeries inputs, iterator,
    handle: (result) -> res = res.concat result
    finish: -> res

Promise.map = (vals, iterator) ->
  res = []

  Promise.each vals, iterator,
    handle: (val, i) -> res[i] = val
    finish: -> res

Promise.settle = (vals, iterator) ->
  res = []
  err = [] 

  Promise.each vals, iterator,
    handle: (result) -> res.push result
    fail: (error) -> err.push error
    finish: -> [ err, res ]

Promise.mapSeries = (inputs, iterator) ->
  res = []

  Promise.eachSeries inputs, iterator,
    handle: (result) -> res.push result
    finish: -> res

Promise.mapLimit = (inputs, concurrency, iterator) ->
  res = []

  Promise.eachLimit inputs, concurrency, iterator,
    handle: (result) -> res.push result
    finish: -> res

Promise.reduce = (vals, iterator, reduction) ->
  iteratee = (val) -> iterator reduction, val

  Promise.eachSeries vals, iteratee,
    handle: (result) -> reduction = result
    finish: -> reduction

Promise.someSeries = (vals, iterator) ->
  found = false
  val = undefined

  Promise.eachSeries vals, iterator,
    handle: (result, i) ->
      return unless result
      val = vals[i]
      found = true
    finish: -> val
    stopEarly: -> found

Promise.some = (vals, iterator) ->
  found = false
  val = undefined

  Promise.each vals, iterator,
    handle: (result, i) ->
      return unless result
      val = vals[i]
      found = true
    finish: -> val
    stopEarly: -> found

Promise.filter = (vals, iterator) ->
  arr = []

  Promise.each vals, iterator,
    handle: (result, i) ->
      arr.push vals[i] if result
    finish: -> arr

Promise.filterSeries = (vals, iterator) ->
  arr = []

  Promise.eachSeries vals, iterator,
    handle: (result, i) ->
      arr.push vals[i] if result
    finish: -> arr

module.exports = asCallback