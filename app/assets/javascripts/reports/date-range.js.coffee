class @DateRange
  constructor: (@type, @offset = 0 ) ->
    @.recalculate()
  setType: (type) ->
    if type != @type
      @offset = 0
      @type = type
      @.recalculate()
  forward: ->
    if @offset > 0
      @offset--
      @.recalculate()
  backward: ->
    @offset++
    @.recalculate()

  recalculate: ->
    if @type == 'halfYear'
      year_offset = @offset / 2
      _moment = moment().subtract(year_offset, 'year')
      if _moment.month() > 5
        @from = _moment.clone().month(6).startOf('month')
        @to = _moment.clone().endOf('year')
      else
        @from = _moment.clone().startOf('year')
        @to = _moment.clone().month(5).endOf('month')
    else
      _moment = moment().subtract(@offset, @type)
      type = @type
      type = "isoweek" if type == 'week' # small patch to make week start from Monday instead of Sunday
      @from = _moment.clone().startOf(type)
      @to = _moment.clone().endOf(type)

  from4rails: -> @from.format()
  to4rails: -> @to.format()

  toString: ->
    if @type is "year"
      "#{ @from.year() }"
    else if @type is "month"
      "#{ @from.format("MMM YYYY") }"
    else if @type is "today"
      "#{ @from.format("DD MMM YYYY") }"
    else if @type is ""
      "All time"
    else
      "#{ @from.format("ll") } - #{ @to.format("ll") }"
