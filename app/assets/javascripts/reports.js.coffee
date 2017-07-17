$(document).ready ->
  $('#selectize-selectmultiple').selectize()

  $('.report-listing a.favorite').on('click', (e) ->
    link  = $(this)
    panel = link.parent()
    panel.toggleClass('favorite')
    favReportsCount = $('#favorite_reports_count')
    favCount = parseInt(favReportsCount.text())
    # console.log favCount
    # if panel.hasClass('favorite') then console.log(favCount-1) else console.log(favCount+1)
    if panel.hasClass('favorite') then favCount++ else favCount--
    favReportsCount.toggleClass('hidden', favCount == 0).text(favCount)
    newTitle = link.data( if panel.hasClass('favorite') then 'tooltip-active' else 'tooltip-inactive' )
    link.tooltip('hide').attr('data-original-title', newTitle).tooltip('fixTitle').tooltip('show')
    $.ajax { url: link.data('href'), type: 'PUT' }
    false
  ).each ->
    link = $(this)
    newTitle = link.data( if link.parent().hasClass('favorite') then 'tooltip-active' else 'tooltip-inactive')
    link.tooltip('hide').attr('data-original-title', newTitle).tooltip('fixTitle')
