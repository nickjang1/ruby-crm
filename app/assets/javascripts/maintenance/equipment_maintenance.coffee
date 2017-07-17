$ ->
  return unless $('body').hasClass('equipment-maintenance-page')

  checklist_group = {}
  maintenance_record = {}
  $table = $('#equipment-maintenance-table')
  group_id = $table.data('group-id')
  type_id = $table.data('type-id')
  equipment_id = $table.data('id')
  record_id = $table.data('record-id')
  checklist_item_ids = -1
  maintenance_status = ''
  maintenance_comment = ''

  checklist_item_template = $('#checklist-item-template').html()
  $submitForm = $('#equipment-fixed-form')

  get_item_maintenance_info = (item_id) ->
    status = $.grep(maintenance_record.checklist_item_maintenances, (elem) ->
      elem.maintenance_checklist_item_id == item_id
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

  render_checklist_items = ->
    $table.find('tbody').html('')
    build_checklist_information()
    for item in checklist_group.checklist_items
      rendered = Mustache.render(checklist_item_template, item)
      $table.find('tbody').append(rendered)
    check_maintenance_completed()

  build_checklist_information = () ->
    checklist_group.completed = false
    completed_count = 0
    maintenance_record.checklist_item_maintenances ||= []
    for item in checklist_group.checklist_items
      maintenance_info = get_item_maintenance_info(item.id)
      status = maintenance_info['status']
      comment = maintenance_info['comment']
      id = maintenance_info['maintenance_id']
      item.status = status
      item.comment = comment
      item.maintenance_id = id
      item.cancel_path = Routes.maintenance_checklist_item_maintenance_path(id) if id
      item.cancel_confirm_msg = "Reset the status of '#{item.name}'?"
      switch status
        when 'no_issues'
          item.no_issues = true
          item.no_maintenance = false
        when 'fixed'
          item.fixed = true
          item.no_maintenance = false
        when 'issues'
          item.issues = true
          item.no_maintenance = false
          item.work_order = maintenance_info.work_order
        else
          item.no_issues = false
          item.fixed = false
          item.issues = false
          item.no_maintenance = true
      completed_count++ unless item.no_maintenance
    checklist_group.completed = true if completed_count == checklist_group.checklist_items.length

  $('#main .indicator').show()
  $.ajax(
    url: Routes.maintenance_equipment_type_equipment_checklist_item_path(type_id, group_id)
    dataType: 'JSON'
  ).done (data) ->
    checklist_group = data
    $('#main .indicator').show()
    $.ajax(
      url: Routes.equipment_maintenance_checklist_item_maintenances_path(),
      dataType: 'JSON',
      data:
        record_id: record_id
        maintainable_type: 'maintenance/equipment'
        maintainable_id: equipment_id
    ).done (data) ->
      maintenance_record = data
      render_checklist_items()
    .complete (data) -> $('#main .indicator').hide()
  .complete (data) -> $('#main .indicator').hide()

  $submitForm.unbind('submit').submit (e) ->
    e.preventDefault()
    $form = $submitForm.parsley()
    if $form.validate()
      $('#room-maintenance-comment-modal').modal('hide')
      maintenance_comment = $submitForm.find('#maintenance-comment').val()
      $(@).find('#equipment-comment-form-submit').attr('disabled', 'disabled')
      update_maintenance_status()

  update_maintenance_status = () ->
    options = 
      method: 'POST'
      url: Routes.maintenance_checklist_item_maintenances_path()

    if maintenance_status == 'issues'
      formData = new FormData($('#equipment-fixed-form')[0])
      formData.append 'maintainable_type', 'Maintenance::Equipment'
      formData.append 'maintainable_id', equipment_id
      formData.append 'checklist_item_ids[]', checklist_item_ids
      formData.append 'status', maintenance_status
      formData.append 'maintenance_work_order[description]', maintenance_comment
      formData.append 'record_id', record_id
      options.data = formData
      options.contentType = false
      options.processData = false
    else
      options.data =
        maintainable_type: 'maintenance/equipment'
        maintainable_id: equipment_id
        checklist_item_ids: checklist_item_ids
        status: maintenance_status
        comment: maintenance_comment
        record_id: record_id
      options.dataType = 'json'

    $.ajax(options)
    .done (updated_status) ->
      maintenance_record.checklist_item_maintenances = $.merge(maintenance_record.checklist_item_maintenances, updated_status)
      render_checklist_items()
      $('#equipment-maintenance-comment-modal').modal('hide')
    .complete ->
      room_maintenance_status = ''
      checklist_item_ids = []
      room_maintenance_comment = ''
      $('#maintenance_comment').val('')
      $('#maintenance-comment-form-submit').removeAttr('disabled')
    .fail (e, data) ->
      $.gritter.add
        time: 5000
        text: e.responseJSON.message
        class_name: "alert alert-danger"

  check_maintenance_completed = ->
    if checklist_group.completed
      fixed_count = 0
      work_order_count = 0
      for item in checklist_group.checklist_items
        if item.fixed
          fixed_count++
        if item.issues
          work_order_count++
      info = 'Great job! You have completed maintenance for this Equipment. '
      if fixed_count > 0
        info += "#{fixed_count} issue(s) fixed"
      if work_order_count > 0
        if fixed_count > 0
          info += " and "
        info += "#{work_order_count} work order(s) created"
      $('#maintenance-information').text(info)
      $('#equipment-maintenance-completed-modal').modal('show')

  $('body').on('click', '.maintenance-action.inactive', (e) ->
    $this = $(@)
    checklist_item_ids = [$this.closest('tr').attr('data-item-id')]
    maintenance_status = $this.attr('data-status')
    $maintenance_comment = $submitForm.find('#maintenance-comment')
    $maintenance_comment.val('')
    $('.magic-tags .tag').removeClass('active')
    $submitForm.parsley().reset()
    if $this.hasClass('issue-fixed')
      $submitForm.find('.fixed-title').removeClass('hidden')
      $submitForm.find('.work-order-title').addClass('hidden')
      $submitForm.find('#maintenance-comment-form-submit').html($submitForm.find('#maintenance-comment-form-submit').attr('data-fixed-label'))
      $maintenance_comment.attr('placeholder', $maintenance_comment.attr('data-fixed-placeholder'))
      $submitForm.find('.wo-attachments').addClass('hidden')
      $('#equipment-maintenance-comment-modal').modal()
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
      $('#equipment-maintenance-comment-modal').modal()
    else
      update_maintenance_status()
    return false
  )

  $('body').on 'ajax:success', '.maintenance-action', (e, data, status, xhr) ->
    maintenance_id = data
    maintenance_record.checklist_item_maintenances = $.grep(maintenance_record.checklist_item_maintenances, (value) ->
      value.id != maintenance_id
    )
    update_maintenance_status()
