throttle = (concurrency, fn) ->
  throw new Error "Concurrency must be equal or higher than 1." unless concurrency >= 1
  throw new Error "Worker must be a function." unless typeof fn is "function"

  numRunning = 0

  queue = []

  startJobs = ->
    startJob job while numRunning < concurrency and job = queue.shift()

  startJob = (job) ->
    rejectedHandler = makeRejectedHandler job

    numRunning++

    try promise = fn.apply job.context, job.arguments
    catch error then return rejectedHandler error

    try promise.then makeFulfilledHandler(job), rejectedHandler
    catch error then return rejectedHandler error

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
  promise = @constructor or Promise

  @then (v) ->
    promise.resolve handler(v)
    v

Promise::asCallback ?= asCallback
Promise::tap ?= tap

Promise.each = (vals, iterator, { concurrency, handle, stopEarly, finish } = {}) ->
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

    resolver = (index) ->
      return (val) ->
        return if stopped

        try handle? val, index
        catch error
          stopped = true
          return reject error

        remaining--

        if remaining is 0 or stopEarly?()
          stopped = true
          resolve finish?()

    for promise, i in promises
      try promise resolver(i), reject
      catch error # there is no then method
        reject error
        stopped = true

Promise.eachLimit = (vals, concurrency, iterator, options = {}) ->
  options.concurrency = concurrency
  @each vals, iterator, options

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
  doBatch @mapSeries, fns

Promise.parallel = (fns) ->
  doBatch @map, fns

Promise.parallelLimit = (fns, concurrency) ->
  mapLimit = @mapLimit

  makeMapFn = (concurrency) ->
    (fns, iterator) ->
      mapLimit fns, concurrency, iterator

  doBatch makeMapFn(concurrency), fns

Promise.map = (vals, iterator) ->
  res = []

  @each vals, iterator,
    handle: (val, i) -> res[i] = val
    finish: -> res

Promise.mapSeries = (inputs, iterator) ->
  res = []

  @eachSeries inputs, iterator,
    handle: (result) -> res.push result
    finish: -> res

Promise.mapLimit = (inputs, concurrency, iterator) ->
  res = []

  @eachLimit inputs, concurrency, iterator,
    handle: (result) -> res.push result
    finish: -> res

Promise.reduce = (vals, iterator, reduction) ->
  iteratee = (val) -> iterator reduction, val

  @eachSeries vals, iteratee,
    handle: (result) -> reduction = result
    finish: -> reduction

Promise.someSeries = (vals, iterator) ->
  found = false
  val = undefined

  @eachSeries vals, iterator,
    handle: (result, i) ->
      return unless result
      val = vals[i]
      found = true
    finish: -> val
    stopEarly: -> found

Promise.some = (vals, iterator) ->
  found = false
  val = undefined

  @each vals, iterator,
    handle: (result, i) ->
      return unless result
      val = vals[i]
      found = true
    finish: -> val
    stopEarly: -> found

Promise.filter = (vals, iterator) ->
  arr = []

  @each vals, iterator,
    handle: (result, i) ->
      arr.push vals[i] if result
    finish: -> arr

Promise.filterSeries = (vals, iterator) ->
  arr = []

  @eachSeries vals, iterator,
    handle: (result, i) ->
      arr.push vals[i] if result
    finish: -> arr

module.exports = asCallback