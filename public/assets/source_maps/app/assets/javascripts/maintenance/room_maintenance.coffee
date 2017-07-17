roomMaintenancePage = ->
  return unless $('body').hasClass('room-maintenance-page')

  areas = []
  room_status = []
  area_checklist_template = $('#area-checklist-template').html()
  $table = $('#area-checklist-table')
  room_id = $table.data('room-id')
  room_number = $table.data('room-number')
  cycle_id = $table.data('cycle-id')
  record_id = $table.data('record-id')
  checklist_item_ids = -1
  current_area_id = -1
  room_maintenance_status = ''
  room_maintenance_comment = ''
  permitted_single_click_pm = $table.attr('permitted-single-click-pm')?
  $currentRowArea = []
  $submitForm = $('#room-fixed-form')

  $submitForm.parsley()

  get_category_maintenance_info = (checklist_id) ->
    status = $.grep(room_status.checklist_item_maintenances, (elem) ->
      elem.maintenance_checklist_item_id == checklist_id
    )
    if status.length > 0
      {
        status: status[0].status,
        comment: status[0].comment,
        work_order: status[0].work_order,
        maintenance_id: status[0].id
      }
    else
      {}

  build_areas_information = () ->
    $.each areas, (i, area) ->
      area.completed = 0
      area.all_completed = false
      $.each area.subcategories, (j, category) ->
        maintenance_info = get_category_maintenance_info(category.id)
        status = maintenance_info['status']
        comment = maintenance_info['comment']
        id = maintenance_info['maintenance_id']
        category.status = status
        category.comment = comment
        category.maintenance_id = id
        category.cancel_path = Routes.maintenance_checklist_item_maintenance_path(id) if id
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
          else
            category.no_issues = false
            category.fixed = false
            category.issues = false
            category.no_maintenance = true
        area.completed++ unless category.no_maintenance
      if area.completed == area.subcategories.length
        area.all_completed = true

  areaDetails = (oTable, nTr) ->
    floor_index = $(nTr).attr('data-area-index')
    area = areas[floor_index]
    $detail = $(Mustache.render(area_checklist_template, area))
    # add plugin initializers here
    $detail

  getAreaTr = (index) ->
    $table.find(".area-row[data-area-index=\"#{index}\"]")

  checkMaintenanceCompleted = ->
    completed = true
    for area in areas
      unless area.all_completed
        completed = false
        break
    if completed
      fixed_count = 0
      work_order_count = 0
      for area in areas
        for category in area.subcategories
          if category.fixed
            fixed_count++
          if category.issues
            work_order_count++
      info = "Great job! You have completed maintenance for Room #{room_number}. "
      if fixed_count > 0
        info += "#{fixed_count} issue(s) fixed"
      if work_order_count > 0
        if fixed_count > 0
          info += " and "
        info += "#{work_order_count} work order(s) created"
      $('#maintenance-information').text(info)
      $('#room-maintenance-completed-modal').modal('show')

  toggleIncompletedRow = ->
    index = if current_area_id == -1 then 0 else current_area_id
    while index < areas.length
      unless areas[index].all_completed
        break
      index++
    index = -1 if index == areas.length
    if current_area_id != -1 && areas[current_area_id].all_completed
      closeAreaRow getAreaTr(current_area_id)[0]
      openAreaRow getAreaTr(index)[0] unless index == -1
      return
    unless index == -1
      closeAreaRow getAreaTr(index)[0], false
      openAreaRow getAreaTr(index)[0], false

  $table.find("thead tr").each ->
    this.insertBefore(document.createElement("th"), this.childNodes[0])

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
    $.ajax(Routes.maintenance_checklist_items_path(cycle_id: cycle_id), { dataType: 'json' })
    .done (categories)->
      areas = categories
      build_areas_information()
      $(areas).each (index, area) ->
        areasTable.api().row.add([
          '<a href="#" class="text-primary area-toggler" style="text-decoration:none;font-size:14px;"><i class="ico-arrow-down2"></i></a>'
          @.name
          if permitted_single_click_pm
            """
            <div class='area-status-div'>
              <a href=\"#\" class='btn btn-outline btn-warning room-area-action' data-confirm=\"Do you want to mark all the checklist items as 'No issue' items for this PM?\">
                <i class='ico-ok fa-fw'></i>
              </a>
              <span class=\"area-status\">[ #{area.completed} / #{ @.subcategories.length } ]</span>
            </div>
            """
          else
            """
            <div class='area-status-div'>
              <span class=\"area-status\">[ #{area.completed} / #{ @.subcategories.length } ]</span>
            </div>
            """
        ]).draw().nodes().to$().addClass("area-row #{if @.all_completed then 'completed'}").attr('data-area-index', index)
      toggleIncompletedRow()
      checkMaintenanceCompleted()
    .complete (data) -> $('#main .indicator').addClass('hide')

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
      if $(window).width() > 400
        width = parseInt($table.find('tbody tr:first-child td:first-child').css('width')) +
          parseInt($table.find('tbody tr:first-child td:nth-child(2)').css('width')) -
          parseInt($table.css('border-width'))
        $(nTr).next().find('tr td:first-child').attr('width', width)

  toggleRow = (nTr) ->
    if areasTable.fnIsOpen(nTr)
      closeAreaRow nTr
    else
      openAreaRow nTr

  updateAreaStatus = ($areaTr) ->
    if $areaTr
      area_index = $areaTr.attr('data-area-index')
      area = areas[area_index]
      $areaTr.find('.area-status').text("[ #{area.completed} / #{area.subcategories.length} ]")
      if area.completed == area.subcategories.length
        $areaTr.addClass('completed')
      else
        $areaTr.removeClass('completed')

  $('body').on('click', 'tr.area-row', (e) ->
    nTr = $(this)[0]
    toggleRow(nTr)
    return false
  )

  $('#room-fixed-form').unbind('submit').submit (e) ->
    e.preventDefault()
    $form = $submitForm.parsley()
    if $form.validate()
      $('#room-maintenance-comment-modal').modal('hide')
      room_maintenance_comment = $submitForm.find('#maintenance-comment').val()
      $(@).find('#fixed-comment-form-submit').attr('disabled', 'disabled')
      updateMaintenanceStatus()

  updateMaintenanceStatus = ->
    options = 
      method: 'POST'
      url: Routes.maintenance_checklist_item_maintenances_path()

    if room_maintenance_status == 'issues'
      formData = new FormData($('#room-fixed-form')[0])
      formData.append 'cycle_id', cycle_id
      formData.append 'record_id', record_id
      formData.append 'maintainable_type', 'Maintenance::Room'
      formData.append 'maintainable_id', room_id
      formData.append 'checklist_item_ids[]', checklist_item_ids
      formData.append 'status', room_maintenance_status
      formData.append 'maintenance_work_order[description]', room_maintenance_comment

      options.data = formData
      options.contentType = false
      options.processData = false
    else
      options.data = 
        cycle_id: cycle_id
        maintainable_type: 'maintenance/room'
        maintainable_id: room_id
        checklist_item_ids: checklist_item_ids
        status: room_maintenance_status
        comment: room_maintenance_comment
        record_id: record_id
      options.dataType = 'json'

    $.ajax(options)
    .done (updated_status) ->
      room_status.checklist_item_maintenances = $.merge(room_status.checklist_item_maintenances, updated_status)
      build_areas_information()
      updateAreaStatus($currentRowArea)
      toggleIncompletedRow()
      checkMaintenanceCompleted()
    .complete ->
      room_maintenance_status = ''
      checklist_item_ids = []
      room_maintenance_comment = ''
      $('#maintenance_comment').val('')
      $('#maintenance-comment-form-submit').removeAttr('disabled')
      $currentRowArea = []
    .fail (e, data) ->
      if e && e.responseJSON
        $.gritter.add
          time: 5000
          text: e.responseJSON.message
          class_name: "alert alert-danger"

  $('body').on('click', '.room-checklist-action.inactive', (e) ->
    $this = $(@)
    checklist_item_ids = [$this.closest('tr').attr('data-item-id')]
    room_maintenance_status = $this.attr('data-status')
    current_area_id = $this.closest('tr.details').prev().attr('data-area-index')
    $currentRowArea = $this.closest('tr.details').prev('tr')
    $maintenance_comment = $submitForm.find('#maintenance-comment')
    $maintenance_comment.val('')
    $('.magic-tags .tag').removeClass('active')
    $submitForm.parsley().reset()
    if $this.hasClass('issue-fixed')
      $submitForm.find('.fixed-title').removeClass('hidden')
      $submitForm.find('.work-order-title').addClass('hidden')
      $submitForm.find('.wo-attachments').addClass('hidden')
      $submitForm.find('#maintenance-comment-form-submit').html($submitForm.find('#maintenance-comment-form-submit').attr('data-fixed-label'))
      $maintenance_comment.attr('placeholder', $maintenance_comment.attr('data-fixed-placeholder'))
      $('#room-maintenance-comment-modal').modal()
    else if $this.hasClass('work-order')
      $submitForm.find('.fixed-title').addClass('hidden')
      $submitForm.find('.work-order-title').removeClass('hidden')
      
      # Refresh attachment fields
      $submitForm.find('.wo-attachments').removeClass('hidden')
      $submitForm.find("input[type='file']").val('')
      $submitForm.find("img").attr('src', '/assets/default_image.png')
      $submitForm.find(".wo-image").addClass('empty')

      $submitForm.find('#maintenance-comment-form-submit').html($submitForm.find('#maintenance-comment-form-submit').attr('data-work-order-label'))
      $maintenance_comment.attr('placeholder', $maintenance_comment.attr('data-work-order-placeholder'))
      $('#room-maintenance-comment-modal').modal()
    else
      updateMaintenanceStatus()
    return false
  )

  $('body').on('click', '.room-checklist-action.active', (e) ->
    $currentRowArea = $(@).closest('tr.details').prev('tr')
  )

  $('body').on 'ajax:success', '.room-checklist-action', (e, data, status, xhr) ->
    maintenance_id = data
    room_status.checklist_item_maintenances = $.grep(room_status.checklist_item_maintenances, (value) ->
      value.id != maintenance_id
    )
    build_areas_information()
    updateAreaStatus($currentRowArea)
    toggleIncompletedRow()

  $('body').on 'click', '.room-area-action', (e) ->
    e.preventDefault()
    e.stopPropagation()
    showConfirmationDialog($(@).data('confirm'), $(@))

  $('body').on 'dialog:confirmed', '.room-area-action', (e) ->
    e.preventDefault()
    current_area_id = $(@).closest('tr.area-row').data('area-index')
    current_area = areas[current_area_id]
    checklist_item_ids = _.pluck(current_area.subcategories, 'id')
    room_maintenance_status = 'no_issues'
    $currentRowArea = $(@).closest('tr.area-row')
    updateMaintenanceStatus()

$(document).ready(roomMaintenancePage)
