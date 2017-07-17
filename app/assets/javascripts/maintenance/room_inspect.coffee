roomInspectPage = ->
  return unless $('body').hasClass('room-inspect-page')

  $table = $('#room-inspect-table')
  room_id = $table.data('room-id')
  room_number = $table.data('room-number')
  cycle_id = $table.data('cycle-id')
  record_id = $table.data('record-id')
  checklist_item_id = -1
  current_area_id = -1
  work_order_comment = ''

  areas = []
  room_status = []
  area_checklist_template = $('#area-checklist-template').html()
  $currentRow = []
  $submitForm = $('#room-work-order-form')

  $table.find("thead tr").each ->
    this.insertBefore(document.createElement("th"), this.childNodes[0])

  get_category_maintenance_info = (checklist_id) ->
    status = $.grep(room_status.checklist_item_maintenances, (elem) ->
      elem.maintenance_checklist_item_id == checklist_id
    )
    if status.length > 0
      {
        status: status[0].status,
        comment: status[0].comment,
        work_order: status[0].work_order,
        maintenance_id: status[0].id,
        inspection_work_order: status[0].inspection_work_order
      }
    else
      false

  build_areas_information = () ->
    added_areas = []
    $.each areas, (i, area) ->
      area.completed = 0
      area.all_completed = false
      added_categories = []
      $.each area.subcategories, (j, category) ->
        maintenance_info = get_category_maintenance_info(category.id)
        added_categories.push j unless maintenance_info
        status = maintenance_info['status']
        comment = maintenance_info['comment']
        id = maintenance_info['maintenance_id']
        category.status = status
        category.comment = comment
        category.maintenance_id = id
        category.cancel_confirm_msg = "Reset the status of '#{category.name}'?"
        switch status
          when 'no_issues'
            category.no_issues = true
            category.no_maintenance = false
          when 'fixed'
            category.fixed = true
            category.no_maintenance = false
          when 'issues'
            category.issues = true
            category.no_maintenance = false
            category.work_order = maintenance_info.work_order
#            category.work_order_path = Routes.
          else
            category.no_issues = false
            category.fixed = false
            category.issues = false
            category.no_maintenance = true
        if maintenance_info['inspection_work_order']
          category.inspected = true
          category.inspection_work_order = maintenance_info.inspection_work_order
          category.cancel_path = Routes.cancel_inspect_maintenance_checklist_item_maintenance_path(id: category.maintenance_id)
        else
          category.inspected = false
        area.completed++ unless category.no_maintenance
      for jj in added_categories.reverse()
        area.subcategories.splice(jj, 1)
      if area.completed == area.subcategories.length
        area.all_completed = true
      added_areas.push i if area.subcategories.length == 0
    for ii in added_areas.reverse()
      areas.splice(ii, 1)

  toggleIncompletedRow = ->
    index = if current_area_id == -1 then 0 else current_area_id
    unless index == -1
      closeAreaRow getAreaTr(index)[0], false
      openAreaRow getAreaTr(index)[0], false

  areasTable = $table.dataTable(
    aoColumnDefs: [
      bSortable: false
      aTargets: [0]
    ]
    bPaginate: false
    bInfo: false
    bSort: false
  )

  $.ajax(
    Routes.maintenance_checklist_item_maintenances_path(),
    dataType: 'json',
    data:
      cycle_id: cycle_id
      maintainable_type: 'maintenance/room'
      maintainable_id: room_id
      record_id: record_id
  ).done (status) ->
    room_status = status
    setup_categories()

  setup_categories = ->
    $('#main .indicator').removeClass('hide')
    $.ajax(Routes.maintenance_checklist_items_path(), { dataType: 'json' }).done (categories)->
      areas = categories
      build_areas_information()
      $(areas).each (index, area) ->
        areasTable.api().row.add([
          '<a href="#" class="text-primary area-toggler" style="text-decoration:none;font-size:14px;"><i class="ico-arrow-down2"></i></a>'
          @.name
          ""
        ]).draw().nodes().to$().addClass("area-row").attr('data-area-index', index)
      toggleIncompletedRow()
      $('#main .indicator').addClass('hide')

  areaDetails = (oTable, nTr) ->
    floor_index = $(nTr).attr('data-area-index')
    area = areas[floor_index]
    $detail = $(Mustache.render(area_checklist_template, area))
    # add plugin initializers here
    $detail

  closeAreaRow = (nTr, animation = true) ->
    if areasTable.fnIsOpen(nTr)
      $(nTr).removeClass("open")
      $(nTr).find('.area-toggler').children().attr("class", "ico-arrow-down2")
      if animation
        $(nTr).next().find('.area-detail-div').slideUp 400, ->
          areasTable.fnClose(nTr)
      else
        areasTable.fnClose(nTr)

  openAreaRow = (nTr, animation = true) ->
    unless areasTable.fnIsOpen(nTr)
      $(nTr).addClass("open")
      $(nTr).find('.area-toggler').children().attr("class", "ico-arrow-up2")
      $div = $(areasTable.fnOpen(nTr, areaDetails(areasTable, nTr), "details np"))
      if animation
        $div.find('.area-detail-div').css('display', 'none')
        $div.find('.area-detail-div').slideDown()
      width = parseInt($table.find('tbody tr:first-child td:first-child').css('width')) +
        parseInt($table.find('tbody tr:first-child td:nth-child(2)').css('width')) -
        parseInt($table.css('border-width'))
      $(nTr).next().find('tr td:first-child').attr('width', width)

  toggleRow = (nTr) ->
    if areasTable.fnIsOpen(nTr)
      closeAreaRow nTr
    else
      openAreaRow nTr

  $('body').on('click', 'tr.area-row', (e) ->
    nTr = $(this)[0]
    toggleRow(nTr)
    return false
  )

  $('#room-work-order-form').unbind('submit').submit (e) ->
    e.preventDefault()
    $form = $submitForm.parsley()
    if $form.validate()
      $('#room-inspection-work-order-modal').modal('hide')
      work_order_comment = $submitForm.find('#work-order-comment').val()
      $(@).find('#work-order-form-submit').attr('disabled', 'disabled')
      updateMaintenanceStatus()

  getAreaTr = (index) ->
    $table.find(".area-row[data-area-index=\"#{index}\"]")

  updateMaintenanceStatus = () ->
    $('#main .indicator').removeClass('hide')
    $.ajax(
      Routes.inspect_maintenance_checklist_item_maintenance_path(id: checklist_item_id)
      dataType: 'JSON'
      method: 'POST'
      data:
        cycle_id: cycle_id
        maintainable_type: 'maintenance/room'
        maintainable_id: room_id
        checklist_item_id: checklist_item_id
        comment: work_order_comment
    ).done((updated_status) ->
      $.each room_status.checklist_item_maintenances, (i, maintenance) ->
        maintenance.inspection_work_order = updated_status.work_order if maintenance.id == updated_status.checklist_item_maintenance_id
      build_areas_information()
      toggleIncompletedRow()
    ).complete( ->
      checklist_item_id = -1
      work_order_comment = ''
      $('#work-order-comment').val('')
      $('#work-order-form-submit').removeAttr('disabled')
      $('#main .indicator').addClass('hide')
    )

  $('body').on('click', '.room-checklist-action.inactive', (e) ->
    $this = $(@)
    checklist_item_id = $this.closest('tr').attr('data-item-id')
    current_area_id = $this.closest('tr.details').prev().attr('data-area-index')
    $work_order_comment = $submitForm.find('#maintenance-comment')
    $work_order_comment.val('')
    $submitForm.parsley().reset()
    $('#room-inspection-work-order-modal').modal()
    return false
  )

  $('body').on('click', '.room-checklist-action.active', (e) ->
    current_area_id = $(@).closest('tr.details').prev().attr('data-area-index')
  )

  $('body').on 'ajax:success', '.room-checklist-action', (e, data, status, xhr) ->
    maintenance_id = data
    $.each room_status.checklist_item_maintenances, (i, maintenance) ->
      delete maintenance.inspection_work_order if maintenance.id == data
    build_areas_information()
    toggleIncompletedRow()

$(document).ready(roomInspectPage)
