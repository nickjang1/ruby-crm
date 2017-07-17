showWeekVsRoomChart= ->
  chartContainer = $('#week-vs-room-chart')
  loading = chartContainer.closest('.indicator')
  
  options =
    chart:
      type: "column"
      height: 250
    title:
      text: "Week Vs # of Rooms"
    xAxis:
      categories: []
      labels:
        formatter: ->
          this.value.toString().split('-').join("<br/>")
    yAxis:
      title:
        text: "Number of Rooms Completed"
      plotLines: [{color: '#ff0000', width: 2, value: 2}]
    series: [
      { name: "Week", data: [], pointPadding: 0.3, pointPlacement: 0, showInLegend: false }
    ]

  #chartContainer.highcharts options
  $.ajax(
      dataType: 'json'
      type: 'GET'
      data: { }
      url: Routes.maintenance_week_vs_completed_rooms_data_path()
      success: (data) ->
        loading.hide()
        options.yAxis.plotLines[0].value = data.average
        options.xAxis.categories = data.weeks
        options.series[0].data = data.no_of_finished_rooms
        chartContainer.highcharts options
    )
  
initRoomMaintenanceProgressChart = ->
  if $('#pm-room-progress-line-chart').length != 0
    option = 
      series:
        lines:
          show: true
          fill: 0.01
      grid:
        borderColor: '#eee'
        borderWidth: 1
        hoverable: true
        backgroundColor: '#fcfcfc'
      tooltip: true
      tooltipOpts: content: '%x : %y'
      xaxis:
        tickColor: '#eee'
        mode: 'categories'
      yaxis: 
        tickColor: '#eee'
      shadowSize: 0
  
    # Load chart data
    $.ajax(
      url: Routes.maintenance_pm_room_progress_data_path()
      cache: false
      type: 'GET'
      dataType: 'json'
    ).done (res) ->
      # init flot
      option.yaxis.max = res.ymax
      option.xaxis.max = res.xmax
      $.plot $('#pm-room-progress-line-chart'), res.data, option
      # hide indicator
      $('#pm-room-progress-line-chart').parents('.panel').find('.indicator').removeClass 'show'


maintenanceDashboardPage = ->
  return unless $('body').hasClass('maintenance-dashboard-page')
  showWeekVsRoomChart()
  initRoomMaintenanceProgressChart()

$(document).ready(maintenanceDashboardPage)
