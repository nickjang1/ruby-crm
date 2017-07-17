publicAreaSelectionPage = ->
  return unless $('body').hasClass('public-area-selection-page')
  
  public_areas = []
  
  floorDetails = (oTable, nTr) ->
    floor_index = $(nTr).attr('data-floor-index')
    Mustache.render(rooms_floor_template, rooms[floor_index])
  
  publicAreasTable = $("#public-area-selection-table").dataTable(
    aoColumnDefs: [
      bSortable: false
      aTargets: [0]
    ]
    bPaginate: false
    bInfo: false
    bSort: false
  )
  
  load_and_build_public_areas_table = (filter_type = 'remaining')->
    publicAreasTable.api().clear().draw()
    $('#main .indicator').removeClass('hide')
    $.ajax(Routes.maintenance_public_areas_path(filter_type: filter_type), {type: 'GET', dataType: 'json'}).done (public_areas)->
      publicAreasTable.api().clear().draw()
      areas = public_areas
      $(areas).each (index) ->
        publicAreasTable.api().row.add([
          if @.done_percentage != undefined
            """#{@.name}<br><span class="badge badge-danger">#{@.done_percentage}% done</span>"""
          else
            "#{@.name}"
          if @.maintenance_in_progress
            """<a href="/maintenance/public_areas/#{@.name.split('/').join('-').split(' ').join('_')}" class="btn btn-success maintenance-btn-xs btn-outline btn-sm start-maintenance">Continue PM</a>"""
          else
            """<a href="/maintenance/public_areas/#{@.name.split('/').join('-').split(' ').join('_')}" class="btn btn-success maintenance-btn-xs btn-outline btn-sm start-maintenance">Start PM</a>"""
        ]).draw().nodes().to$().addClass('floor-row').attr('data-floor-index', index).find('td:eq(1)').addClass('text-center maintenance-td')
    .complete (data) -> $('#main .indicator').addClass('hide')
  load_and_build_public_areas_table()

  $('a[data-filter-type]').on 'click', ->
    load_and_build_public_areas_table( $(@).data('filter-type') )
    $(@).siblings().removeClass('btn-primary').addClass('btn-default')
    $(@).addClass('btn-primary').removeClass('btn-default')

publicAreaMaintenancePage = ->
  return unless $('body').hasClass('public-area-maintenance-page')
  
  $table = $('#area-checklist-table')
  checklist_name_template = $('#checklist-name-template').html()
  checklist_actions_template = $('#checklist-actions-template').html()
  areas = []
  public_area_status = []
  public_area_id = $table.data('public-area-id')
  cycle_id = $table.data('cycle-id')
  record_id = $table.data('record-id')
  public_area_maintenance_status = ''
  public_area_maintenance_comment = ''
  checklist_item_ids = -1
  $submitForm = $('#public-area-fixed-form')

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
        maintenance_id: status[0].id
      }
    else
      {}

  populate_checklist_items_of_public_area = () -> 
    $(areas).each (index, area) ->
        areasTable.api().row.add([
          $(Mustache.render(checklist_name_template, area)).html()
          $(Mustache.render(checklist_actions_template, area)).html()
        ]).draw().nodes().to$().attr('data-item-id', area.id)
        $("tr td:nth-child(2)").addClass('maintenance-actions');
        $("tr td:nth-child(1)").addClass('checklist-item-name');   
  
  build_areas_information = () ->
    completed = 0 
    for area, i in areas

      maintenance_info = get_category_maintenance_info(area.id)
      status = maintenance_info['status']
      comment = maintenance_info['comment']
      id = maintenance_info['maintenance_id']
      area.status = status
      area.comment = comment
      area.maintenance_id = id
      area.cancel_path = Routes.maintenance_checklist_item_maintenance_path(id) if id
      area.cancel_confirm_msg = "Reset the status of '#{area.name}'?"
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
      completed++ unless area.no_maintenance
    if completed == areas.length
        showMaintenanceModal()
  
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

  showMaintenanceModal = ->
    info = "Great job! You have completed maintenance for public area"
    $('#maintenance-information').text(info)
    $('#public-area-maintenance-completed-modal').modal('show')
  
  $('#public-area-fixed-form').unbind('submit').submit (e) ->
    e.preventDefault()
    $form = $submitForm.parsley()
    if $form.validate()
      $('#public-area-maintenance-comment-modal').modal('hide')
      public_area_maintenance_comment = $submitForm.find('#maintenance-comment').val()
      $(@).find('#fixed-comment-form-submit').attr('disabled', 'disabled')
      updateMaintenanceStatus()

  updateMaintenanceStatus = ->
    options = 
      method: 'POST'
      url: Routes.maintenance_checklist_item_maintenances_path()

    if public_area_maintenance_status == 'issues'
      formData = new FormData($('#public-area-fixed-form')[0])
      formData.append 'cycle_id', cycle_id
      formData.append 'maintainable_type', 'Maintenance::PublicArea'
      formData.append 'maintainable_id', public_area_id
      formData.append 'checklist_item_ids[]', checklist_item_ids
      formData.append 'status', public_area_maintenance_status
      formData.append 'maintenance_work_order[description]', public_area_maintenance_comment
      formData.append 'record_id', record_id
      
      options.data = formData
      options.contentType = false
      options.processData = false
    else
      options.data = 
        cycle_id: cycle_id
        maintainable_type: 'maintenance/public_area'
        maintainable_id: public_area_id
        checklist_item_ids: checklist_item_ids
        status: public_area_maintenance_status
        comment: public_area_maintenance_comment
        record_id: record_id
      options.dataType = 'json'

    $.ajax(options)
    .done (updated_status) ->
      public_area_status.checklist_item_maintenances = $.merge(public_area_status.checklist_item_maintenances, updated_status)
      build_areas_information()
      areasTable.api().clear()
      populate_checklist_items_of_public_area()
    .complete ->
      public_area_maintenance_status = ''
      checklist_item_ids = []
      public_area_maintenance_comment = ''
      $('#maintenance_comment').val('')
      $('.magic-tags .tag').removeClass('active')
      $('#maintenance-comment-form-submit').removeAttr('disabled')
      $currentRow = []
    .fail (e, data) ->
      $.gritter.add
        time: 5000
        text: e.responseJSON.message
        class_name: "alert alert-danger"

  $('body').on('click', '.room-checklist-action.inactive', (e) ->
    $this = $(@)
    checklist_item_ids = [$this.closest('tr').attr('data-item-id')]
    public_area_maintenance_status = $this.attr('data-status')
    current_area_id = $this.closest('tr.details').prev().attr('data-area-index')
    $currentRow = $this
    $maintenance_comment = $submitForm.find('#maintenance-comment')
    $maintenance_comment.val('')
    $submitForm.parsley().reset()
    if $this.hasClass('issue-fixed')
      $submitForm.find('.fixed-title').removeClass('hidden')
      $submitForm.find('.work-order-title').addClass('hidden')
      $submitForm.find('#maintenance-comment-form-submit').html($submitForm.find('#maintenance-comment-form-submit').attr('data-fixed-label'))
      $maintenance_comment.attr('placeholder', $maintenance_comment.attr('data-fixed-placeholder'))
      $submitForm.find('.wo-attachments').addClass('hidden')
      $('#public-area-maintenance-comment-modal').modal()
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
      $('#public-area-maintenance-comment-modal').modal()
    else
      updateMaintenanceStatus()
    return false
  )

  $('body').on 'ajax:success', '.room-checklist-action', (e, data, status, xhr) ->
    maintenance_id = data
    public_area_status.checklist_item_maintenances = $.grep(public_area_status.checklist_item_maintenances, (value) ->
      value.id != maintenance_id
    )
    build_areas_information()
    updateMaintenanceStatus()


$(document).ready(publicAreaSelectionPage)
$(document).ready(publicAreaMaintenancePage)
