module.exports = ->

  @factory 'InterpolateFilters', (InterpolateToFunction, Interpolate, utils, debug, moment) ->

    preprocessDate = (value) ->
      if moment.isMoment(value) then value else moment value

    Interpolate

      .filter 'filter', (array, str) ->
        console.log 'filter', array, str

        predicateFn = InterpolateToFunction str
        Array::filter.call array, predicateFn

      .filter 'repeat', (ctx, val) ->
        template = interpolate.templates[val]

        process = (obj) =>
          newCtx = utils.clone @scope
          newCtx.scope[val] = obj

          Interpolate.walk template, newCtx

        if Array.isArray ctx
          ctx.map process
        else
          process val

      .filter 'camel', (val = '') ->
        val.charAt(0).toUpperCase() + val.slice(1).toLowerCase()

      .filter 'proper', (val = '') ->
        val.replace /\w\S*/g, (txt) -> txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

      .filter 'caps', (val = '') ->
        val.toUpperCase()

      .filter 'lower', (val = '') ->
        val.toLowerCase()

      .filter 'amRelative', (val) ->
        { start, end } = val

        if start and end
          str =
            between: [
              start.toDate()
              end.toDate()
            ]
        else if start
          str = gte: start.toDate()
        else if end
          str = lte: end.toDate()

        str

      .filter 'amParse', (value, format) ->
        moment value, format

      .filter 'amFromUnix', (value) ->
        moment.unix value

      .filter 'amISOString', (value) ->
        aMoment = preprocessDate(value)
        aMoment.toISOString()

      .filter 'amDate', (value) ->
        aMoment = preprocessDate(value)
        aMoment.toDate()

      .filter 'amUtc', (value) ->
        moment.utc value

      .filter 'amWeekday', (value) ->
        aMoment = preprocessDate(value)
        aMoment.weekday()

      .filter 'amISOWeekday', (value) ->
        aMoment = preprocessDate(value)
        aMoment.isoWeekday()

      .filter 'amUtcOffset', (value, offset) ->
        preprocessDate(value).utcOffset offset

      .filter 'amLocal', (value) ->
        if moment.isMoment(value) then value.local() else null

      .filter 'amTimezone',  (value, timezone) ->
        aMoment = preprocessDate(value)

        if !timezone
          return aMoment

        if aMoment.tz
          aMoment.tz timezone
        else
          console.log 'angular-moment: named timezone specified but moment.tz() is undefined. Did you forget to include moment-timezone.js ?'

          aMoment

      .filter 'amCalendar', (value, referenceTime, formats) ->
        if not value?
          return ''

        date = preprocessDate(value)

        if date.isValid() then date.calendar(referenceTime, formats) else ''

      .filter 'amDifference', (value, otherValue, unit, usePrecision) ->
        if not value?
          return ''

        date = preprocessDate(value)
        date2 = if otherValue? then preprocessDate(otherValue) else moment()

        if !date.isValid() or !date2.isValid()
          return ''

        date.diff date2, unit, usePrecision

      .filter 'amDateFormat', (value, format) ->
        if not value?
          return ''

        date = preprocessDate(value)

        if !date.isValid()
          return ''

        date.format format

      .filter 'amDurationFormat', (value, format, suffix) ->
        if not value?
          return ''

        moment.duration(value, format).humanize suffix

      .filter 'amTimeAgo', (value, suffix, from) ->
        if not value?
          return ''

        value = preprocessDate(value)
        date = moment(value)

        if !date.isValid()
          return ''

        dateFrom = moment(from)

        if from? and dateFrom.isValid()
          return date.from(dateFrom, suffix)

        date.fromNow suffix

      .filter 'amAddDuration', (value, duration) ->
        if not value?
          return ''

        duration = moment.duration duration
        value = preprocessDate value

        value.add duration

      .filter 'amSubtractDuration', (value, duration) ->
        if not value?
          return ''

        duration = moment.duration duration
        value = preprocessDate value

        value.subtract duration

      .filter 'amSet', (value, amount, type) ->
        if not value?
          return ''

        moment(value).set type, parseInt(amount, 10)

      .filter 'amSubtract', (value, amount, type) ->
        if not value?
          return ''

        moment(value).subtract parseInt(amount, 10), type

      .filter 'amAdd', (value, amount, type) ->
        if not value?
          return ''

        moment(value).add parseInt(amount, 10), type

      .filter 'amStartOf', (value, type) ->
        if not value?
          return ''

        moment(value).startOf type

      .filter 'amEndOf', (value, type) ->
        if not value?
          return ''

        moment(value).endOf type

    return