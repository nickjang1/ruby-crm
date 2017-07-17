publicAreaInspectPage = ->
  return unless $('body').hasClass('public-area-inspect-page')

  $table = $('#public-area-checklist-table')
  checklist_item_template = $('#public-area-checklist-item-template').html()
  areas = []
  public_area_status = []
  public_area_id = $table.data('public-area-id')
  cycle_id = $table.data('cycle-id')
  record_id = $table.data('record-id')
  public_area_maintenance_status = ''
  public_area_maintenance_comment = ''
  checklist_item_id = -1
  $submitForm = $('#public-area-work-order-form')
  work_order_comment = ''

  $submitForm.parsley()

  get_category_maintenance_info = (checklist_id) ->
    status = $.grep(public_area_status.checklist_item_maintenances, (elem) ->
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

  populate_checklist_items_of_public_area = () ->
    areasTable.api().clear()
    build_areas_information()
    $(areas).each (index, area) ->
      areasTable.api().row.add([
        $(Mustache.render(checklist_item_template, area)).html()
      ]).draw().nodes().to$().attr('data-item-id', area.maintenance_id)

  build_areas_information = () ->
    completed = 0
    added_areas = []
    for area, i in areas
      return true if typeof area == 'undefined'
      maintenance_info = get_category_maintenance_info(area.id)
      added_areas.push i unless maintenance_info
      status = maintenance_info['status']
      comment = maintenance_info['comment']
      id = maintenance_info['maintenance_id']
      area.status = status
      area.comment = comment
      area.maintenance_id = id
      area.cancel_path = Routes.maintenance_checklist_item_maintenance_path(id) if id
      switch status
        when 'no_issues'
          area.no_issues = true
          area.no_maintenance = false
        when 'fixed'
          area.fixed = true
          area.no_maintenance = false
        when 'issues'
          area.issues = true
          area.no_maintenance = false
          area.work_order = maintenance_info.work_order
        else
          area.no_issues = false
          area.fixed = false
          area.issues = false
          area.no_maintenance = true
      if maintenance_info['inspection_work_order']
        area.inspected = true
        area.inspection_work_order = maintenance_info.inspection_work_order
        area.cancel_path = Routes.cancel_inspect_maintenance_checklist_item_maintenance_path(id: area.maintenance_id)
      else
        area.inspected = false
    for ii in added_areas.reverse()
      areas.splice(ii, 1)

  areasTable = $table.dataTable(
    aoColumnDefs: [
      bSortable: false
      aTargets: [0]
    ]
    bPaginate: false
    bInfo: false
    bSort: false
  )
  $('#main .indicator').removeClass('hide')
  $.ajax(
    Routes.maintenance_checklist_item_maintenances_path(),
    dataType: 'json',
    data:
      cycle_id: cycle_id
      maintainable_type: 'maintenance/public_area'
      maintainable_id: public_area_id
      record_id: record_id
  ).done (status) ->
    public_area_status = status
    setup_categories()
  .complete (data) -> $('#main .indicator').addClass('hide')

  setup_categories = ->
    $.ajax(Routes.checklist_items_maintenance_public_areas_path({id: $table.data('public-area-id'), cycle_id: cycle_id}), {type: 'GET', dataType: 'json'}).done (public_areas)->
      areas = public_areas
      build_areas_information()
      populate_checklist_items_of_public_area()

  updateMaintenanceStatus = () ->
    $.ajax(
      Routes.inspect_maintenance_checklist_item_maintenance_path(id: checklist_item_id)
      dataType: 'JSON'
      method: 'POST'
      data:
        cycle_id: cycle_id
        maintainable_type: 'maintenance/public_area'
        maintainable_id: public_area_id
        checklist_item_id: checklist_item_id
        comment: work_order_comment
    ).done((updated_status) ->
      $.each public_area_status.checklist_item_maintenances, (i, maintenance) ->
        maintenance.inspection_work_order = updated_status.work_order if maintenance.id == updated_status.checklist_item_maintenance_id
      populate_checklist_items_of_public_area()
    ).complete( ->
      checklist_item_id = -1
      work_order_comment = ''
      $('#work-order-comment').val('')
      $('#work-order-form-submit').removeAttr('disabled')
    )

  $('body').on 'ajax:success', '.room-checklist-action', (e, data, status, xhr) ->
    maintenance_id = data
    $.each public_area_status.checklist_item_maintenances, (i, maintenance) ->
      delete maintenance.inspection_work_order if maintenance.id == data
    populate_checklist_items_of_public_area()

  $('body').on('click', '.room-checklist-action.inactive', (e) ->
    $this = $(@)
    checklist_item_id = $this.closest('tr').attr('data-item-id')
    current_area_id = $this.closest('tr.details').prev().attr('data-area-index')
    $work_order_comment = $submitForm.find('#work-order-comment')
    $work_order_comment.val('')
    $submitForm.parsley().reset()
    $('#public-area-inspection-work-order-modal').modal()
    return false
  )

  $('#public-area-work-order-form').unbind('submit').submit (e) ->
    e.preventDefault()
    $form = $submitForm.parsley()
    if $form.validate()
      $('#public-area-inspection-work-order-modal').modal('hide')
      work_order_comment = $submitForm.find('#work-order-comment').val()
      $(@).find('#work-order-form-submit').attr('disabled', 'disabled')
      updateMaintenanceStatus()

$(document).ready(publicAreaInspectPage)
