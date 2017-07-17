roomInspectionPage = ->
  return unless $('body').hasClass('room-inspection-page')

  rooms = []
  room_template = $('#room-inspect-template').html()

  roomsTable = $("#rooms-inspection-table").dataTable(
    aoColumnDefs: [
      bSortable: false
      aTargets: [0]
    ]
    bPaginate: false
    bInfo: false
    bSort: false
    bAutoWidth: false
    oLanguage:
      sZeroRecords: 'No Guest Rooms have been maintained in the cycle.'
  )

  load_and_build_rooms_table = ()->
    roomsTable.api().clear().draw()
    $('#main .indicator').removeClass('hide')
    $.ajax(Routes.inspection_maintenance_rooms_path(), {type: 'GET', dataType: 'json'}).done (rooms_by_floor)->
      rooms = rooms_by_floor
      $(rooms).each (index, room) ->
        $rowNode = roomsTable.api().row.add([
          Mustache.render(room_template, room)
        ]).draw().nodes().to$()
        $rowNode.addClass('floor-row')
    .complete (data) -> $('#main .indicator').addClass('hide')

  load_and_build_rooms_table()

$(document).ready(roomInspectionPage)
