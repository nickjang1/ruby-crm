publicAreaInspectionPage = ->
  return unless $('body').hasClass('public-area-inspection-page')

  publicAreaTemplate = $('#public-area-template').html()

  renderPublicArea = (public_area) ->
    Mustache.render(publicAreaTemplate, public_area)

  publicAreasTable = $("#public-area-inspection-table").dataTable(
    aoColumnDefs: [
      bSortable: false
      aTargets: [0]
    ]
    bPaginate: false
    bInfo: false
    bSort: false
    bAutoWidth: false
    oLanguage:
      sZeroRecords: 'No Public Areas have been maintained in the cycle.'
  )

  load_and_build_public_areas_table = ->
    $('#main .indicator').removeClass('hide')
    $.ajax(Routes.inspection_maintenance_public_areas_path(), {type: 'GET', dataType: 'json'}).done (public_areas)->
      areas = public_areas
      $(areas).each (index, area) ->
        area.public_area_inspect_path = Routes.inspect_maintenance_public_area_path(id: area.id)
        publicAreasTable.api().row.add([
          renderPublicArea(area)
        ]).draw()
    .complete (data) -> $('#main .indicator').addClass('hide')

  load_and_build_public_areas_table()

$(document).ready(publicAreaInspectionPage)
