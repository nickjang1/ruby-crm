roomSelectionPage = ->
  return unless $('body').hasClass('room-selection-page')

  rooms = []
  rooms_floor_template = $('#rooms-floor-template').html()

  floorDetails = (oTable, nTr) ->
    floor_index = $(nTr).attr('data-floor-index')
    Mustache.render(rooms_floor_template, rooms[floor_index])

  $("#room-selection-table thead tr").each ->
    this.insertBefore(document.createElement("th"), this.childNodes[0])

  roomsTable = $("#room-selection-table").dataTable(
    aoColumnDefs: [
      bSortable: false
      aTargets: [0]
    ]
    bPaginate: false
    bInfo: false
    bSort: false
  )

  load_and_build_rooms_table = (filter_type = 'remaining')->
    roomsTable.api().clear().draw()
    $('#main .indicator').removeClass('hide')
    $.ajax(Routes.maintenance_rooms_path(filter_type: filter_type), {type: 'GET', dataType: 'json'})
    .done (rooms_by_floor)->
      roomsTable.api().clear().draw()
      rooms = rooms_by_floor
      $(rooms).each (index) ->
        roomsTable.api().row.add([
          '<a href="#" class="text-primary floor-toggler" style="text-decoration:none;font-size:14px;"><i class="ico-plus-circle"></i></a>'
          "Floor #{@.floor}"
          """<span class="label label-success">#{ @.rooms.length }</span>"""
        ]).draw().nodes().to$().addClass('floor-row').attr('data-floor-index', index).find('td:eq(2)').addClass('text-center')
    .complete (data) -> $('#main .indicator').addClass('hide')

  load_and_build_rooms_table()

  $('a[data-filter-type]').on 'click', ->
    load_and_build_rooms_table( $(@).data('filter-type') )
    $(@).siblings().removeClass('btn-primary').addClass('btn-default')
    $(@).addClass('btn-primary').removeClass('btn-default')

  $('body').on('click', '#room-selection-table tr.floor-row', (e) ->
    nTr = $(this)[0]
    $(nTr).toggleClass("open")
    if roomsTable.fnIsOpen(nTr)
      $(this).find('.floor-toggler').children().attr("class", "ico-plus-circle")
      roomsTable.fnClose(nTr)
    else
      $(this).find('.floor-toggler').children().attr("class", "ico-minus-circle")
      roomsTable.fnOpen(nTr, floorDetails(roomsTable, nTr), "details np")
      width = parseInt($('#room-selection-table thead th:first-child').css('width')) +
          parseInt($('#room-selection-table thead th:nth-child(2)').css('width')) -
          (parseInt($('#room-selection-table').css('border-width')) || 0)
      $(nTr).next().find('tr td:first-child').attr('width', width)
    e.preventDefault()
  )

$(document).ready(roomSelectionPage)
