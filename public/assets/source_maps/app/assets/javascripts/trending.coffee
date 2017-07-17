$(document).ready ->
  return unless $('body').hasClass('has-trending-chart')

  filter = ''
  maintenance_trending = $ ('#maintenance-trending')
  dateRange = new DateRange('custom')
  dataWords = []
  property_id = window.property_id
  activeWord = window.activeWord

  renderTrends = ->
    maintenance_trending.css("width", "100%")
    maintenance_trending.empty()
    maintenance_trending.jQCloud(dataWords,
      height: 200
      removeOverflowing: false
    )

  loadTrends = ()->
    $('#trending-spinner').show()
    if cloudReport
      dateRange.from = $('#trending-date-range').data('daterangepicker').startDate
      dateRange.to = $('#trending-date-range').data('daterangepicker').endDate
    else
      if filter == 'last-1'
        dateRange.from = moment().subtract(1, 'months')
      else if filter == 'last-6'
        dateRange.from = moment().subtract(6, 'months')
      else
        dateRange.from = moment().subtract(3, 'months')
      dateRange.from = dateRange.from.startOf('day')
      dateRange.to = moment().endOf('day')
    params =
      from: dateRange.from4rails()
      to: dateRange.to4rails()
    params.property_id = property_id if property_id
    $.ajax(
      dataType: 'json'
      type: 'GET'
      url: Routes.trends_maintenance_work_orders_path(params)
    ).done (data) ->
      dataWords = _.map(data, (e) ->
        e.html = {class: 'trending-word', 'data-ids': e.ids}
        e.handlers =
          click: (e) ->
            $('.trending-word').removeClass('active')
            $(@).addClass('active')
            activeWord = $(@).text()
            if cloudReport
              $(@).trigger('trending.clicked', [property_id])
            else
              options =
                active_word: activeWord
                from: dateRange.from4rails()
                to: dateRange.from4rails()
              options.property_id = property_id if property_id
              url = Routes.report_path('work_order_trendings', options)
              window.location = url
        e.afterWordRender = (e) ->
          if activeWord != 'false' && $(@).text() == activeWord
            $(@).addClass('active')
            $(@).trigger('click')
        e
      )
      renderTrends()
    .complete ->
      $('#trending-spinner').hide()

  showTrendingDate = (start, end) ->
    $('#trending-date-range #range-value').html(start.format('MMM DD, YYYY') + ' - ' + end.format('MMM DD, YYYY'))

  $('#trending-date-range').daterangepicker(
    ranges:
      'Last 1 month': [moment().subtract(1, 'months').startOf('day'), moment().endOf('day')]
      'Last 3 month': [moment().subtract(3, 'months').startOf('day'), moment().endOf('day')]
      'Last 6 month': [moment().subtract(6, 'months').startOf('day'), moment().endOf('day')]
    startDate: moment().subtract(3, 'months')
    autoApply: false
    linkedCalendars: false
    opens: 'left'
  , showTrendingDate)

  $('#trending-date-range').on 'apply.daterangepicker', (e, picker) ->
    loadTrends()

  $('.trending-filter').on 'click', (e) ->
    e.preventDefault()
    return false if filter == $(@).data('filter')
    filter = $(@).data('filter')
    $('#trending-filter-label').text($(@).text())
    loadTrends()

  $('.trending-property').on 'click', (e) ->
    e.preventDefault()
    property_id = $(@).data('id')
    $('#trending-property-label').text($(@).text())
    loadTrends()
    maintenance_trending.trigger('trending.clear')

  if cloudReport
    showTrendingDate(moment().subtract(3, 'months'), moment())
    if property_id
      $(".trending-property[data-id=\"#{property_id}\"]").trigger('click')
    else
      loadTrends()
  else
    $('.trending-filter[data-filter="last-3"]').trigger('click')
