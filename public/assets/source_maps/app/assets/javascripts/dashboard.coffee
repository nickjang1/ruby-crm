showCategorySpendChart = ->
  dateRange = new DateRange('month')
  options =
    series: { pie: { show: true, innerRadius: 0.5 }}
    grid: { hoverable: true }
    tooltip: true
    tooltipOpts: { content: "$%y.0, %s" }
      
  chartContainer = $('#category-spend-chart')
  $.ajax(
    dataType: 'json'
    type: 'GET'
    url: Routes.report_path( 'render/category_spend', from: dateRange.from4rails(), to: dateRange.to4rails() )
    success: (data) ->
      totalSpend = 0
      totalSpend += parseFloat(val) for val in $.map(data, (elem)-> elem.spend)
      chartData =
        if data.length
          $.map(data, (elem)-> {label: elem.category_name, data: elem.spend})
        else
          options.grid.hoverable = false
          [{ label: 'No data available', data: 1 }]
      $.plot(chartContainer, chartData, options)
      $("<div id=\"total-spend\">Total Spend: $#{ totalSpend }</div>")
        .css({'margin-left': - $('#category-spend-chart .legend > div').innerWidth() / 2 - 35 }).show().appendTo(chartContainer)
    )

showBudgetAndSpendChart = ->
  chartContainer = $('#budget-and-spend-chart')
  loading = chartContainer.closest('.indicator')

  options =
    chart: { type: "column" }
    title: { text: "Spend & Budget by Category" }
    xAxis: { categories: [] }
    yAxis: [ { min: 0, labels: { format: '${value}' },  title: { text: "Amount" }} ]
    credits: { enabled: false }
    legend: { shadow: false }
    tooltip: { shared: true, valuePrefix: "$", valueDecimals: $priceFormatDecimalsCount }
    plotOptions: { column: { grouping: false, shadow: false, borderWidth: 0 }}
    series: [
      { name: "Budget", color: "#00B1E1", data: [], pointPadding: 0.3, pointPlacement: 0 }
      { name: "Spend", color: "#91C854", data: [], pointPadding: 0.4, pointPlacement: 0 }
    ]

  drawChart = (range)->
    loading.show()
    $.ajax(
      dataType: 'json'
      type: 'GET'
      data: { range: range }
      url: Routes.spend_vs_budgets_data_path()
      success: (data) ->
        loading.hide()
        options.xAxis.categories = data.categories
        options.series[0].data = data.data.budget
        options.series[1].data = data.data.spend
        chartContainer.highcharts options
    )
  $('#budget-vs-spend-time-selector ul a').on 'click', ->
    drawChart $(this).data('range')
    $(@).parents('#budget-vs-spend-time-selector').find('.status').text( moment().format({ month: "YYYY & MMM", year: "YYYY" }[$(@).data('range')] ))

  $('#budget-vs-spend-time-selector ul a[data-range="month"]').click()

dashboardPage = ->
  return unless $('body').hasClass('dashboard-page')
  showCategorySpendChart()
  showBudgetAndSpendChart()

$(document).ready(dashboardPage)
