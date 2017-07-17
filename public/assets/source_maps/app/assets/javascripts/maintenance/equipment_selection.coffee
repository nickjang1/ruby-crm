$ ->
  return unless $('body').hasClass('equipment-selection-page')

  equipment_types = []
  maintenance_records = []
  equipment_type_template = $('#equipment-type-template').html()
  equipment_type_in_progress_template = $('#equipment-type-in-progress-template').html()
  equipment_modal = $('#equipment-modal')
  equipment_modal_template = $('#equipment-modal-template').html()
  current_equipment_id = -1
  current_filter_type = ''

  equipment_type_details = (oTable, nTr) ->
    type_index = $(nTr).data('type-id')
    if current_filter_type == 'remaining'
      Mustache.render(equipment_type_template, equipment_types[type_index])
    else
      Mustache.render(equipment_type_in_progress_template, equipment_types[type_index])

  build_equipment_modal = (record) ->
    Mustache.render(equipment_modal_template, record)

  toggle_equipment_modal = (record, status) ->
    rendered = build_equipment_modal(record)
    equipment_modal.find('.modal-dialog').html(rendered)
    equipment_modal.modal(status)

  get_maintenance_record = (equipment_id, group_id) ->
    for record in maintenance_records
      if record.maintainable_id == equipment_id && record.equipment_checklist_group_id == group_id
        return record
    return false

  build_equipment_maintenances = ->
    for type in equipment_types
      type.in_progress = 0
      for equipment in type.active_equipments
        equipment.maintenances = []
        for group in type.checklist_groups
          record = get_maintenance_record(equipment.id, group.id)
          equipment.maintenances.push group.id if record
        type.in_progress += 1 if equipment.maintenances.length > 0
      type.equipments_in_progress = []
      for equipment in type.active_equipments
        for group_id in equipment.maintenances
          group = $.grep(type.checklist_groups, (item) -> item.id == group_id)[0]
          in_progress = $.extend(true, {}, equipment)
          in_progress.group_name = group.name
          in_progress.maintenance_path = Routes.maintenance_equipment_path(equipment.id, group_id: group_id)
          type.equipments_in_progress.push in_progress

  $("#equipment-selection-table thead tr").each ->
    this.insertBefore(document.createElement("th"), this.childNodes[0])

  equipmentsTable = $("#equipment-selection-table").dataTable(
    aoColumnDefs: [
      bSortable: false
      aTargets: [0]
    ]
    bPaginate: false
    bInfo: false
    bSort: false
    bAutoWidth: false
    oLanguage:
      sZeroRecords: 'No Equipments have been setup.'
  )

  load_and_build_equipments_table = (filter_type = 'remaining')->
    current_filter_type = filter_type
    $('#main .indicator').show()
    equipmentsTable.api().clear().draw()
    $.ajax(Routes.maintenance_equipments_path(filter_type: filter_type), {type: 'GET', dataType: 'json'})
    .done (data) ->
      equipment_types = data
      $('#main .indicator').removeClass('hide')
      $.ajax(Routes.maintenance_records_path(status: 'in_progress', type: "Maintenance::Equipment"),
        type: 'GET',
        dataType: 'JSON'
      ).done (records) ->
        equipmentsTable.api().clear().draw()
        maintenance_records = records
        build_equipment_maintenances()
        $(equipment_types).each (index) ->
          if (current_filter_type == 'remaining' && @.active_equipments.length > 0) || ((current_filter_type == 'in_progress' && @.equipments_in_progress.length > 0))
            equipmentsTable.api().row.add([
              '<a href="#" class="text-primary type-toggler" style="text-decoration:none;font-size:14px;"><i class="ico-plus-circle"></i></a>'
              """#{@.name} <span class="label label-success ml15">#{ if filter_type == 'remaining' then @.active_equipments.length else @.in_progress }</span>"""
            ]).draw().nodes().to$().addClass('equipment-type-row').attr('data-type-id', index).find('td:eq(2)').addClass('text-center')
      .complete (res) -> $('#main .indicator').hide()
    .complete (res) -> $('#main .indicator').hide()
  load_and_build_equipments_table()

  $('a[data-filter-type]').on 'click', ->
    load_and_build_equipments_table( $(@).data('filter-type') )
    $(@).siblings().removeClass('btn-primary').addClass('btn-default')
    $(@).addClass('btn-primary').removeClass('btn-default')

  $('body').on('click', '#equipment-selection-table tr.equipment-type-row', (e) ->
    nTr = $(this)[0]
    $(nTr).toggleClass("open")
    if equipmentsTable.fnIsOpen(nTr)
      $(this).find('.type-toggler').children().attr("class", "ico-plus-circle")
      equipmentsTable.fnClose(nTr)
    else
      $(this).find('.type-toggler').children().attr("class", "ico-minus-circle")
      equipmentsTable.fnOpen(nTr, equipment_type_details(equipmentsTable, nTr), "details np")
    e.preventDefault()
  )

  $('body').on 'click', '.start-maintenance', (e) ->
    unless $(@).hasClass('continue')
      type_index = $(@).parents('tr.details').prev().data('type-id')
      type = $.extend(true, {}, equipment_types[type_index])
      current_equipment_id = $(@).parents('.equipment-item').data('id')
      equipment = $.grep(type.active_equipments, (item) -> item.id == current_equipment_id)[0]
      for group in type.checklist_groups
        group.in_progress = group.id in equipment.maintenances
      toggle_equipment_modal(type, 'show')
      return false

  $('body').on 'click', '.checklist-group-item', (e) ->
    $('.table-checklist-groups tr input[type=checkbox]').removeAttr('checked')
    $('.table-checklist-groups tr input[type=checkbox]').trigger('change')
    $(@).find('input[type=checkbox]').attr('checked', 'checked')
    $(@).find('input[type=checkbox]').trigger('change')
    if $(@).data('in-progress')
      $('#start-maintenance').text('Continue PM')
    else
      $('#start-maintenance').text('Start PM')
    $('#start-maintenance').removeAttr('disabled')

  $('body').on 'click', '#start-maintenance', (e) ->
    unless current_equipment_id == -1
      $item = $($.grep($('.table-checklist-groups tr input[type=checkbox]'), (item) -> $(item).is(':checked'))[0])
      if $item && $item.length > 0
        group_id = $item.data('group-id')
        window.location = Routes.maintenance_equipment_path(current_equipment_id, group_id: group_id)
      else
        $.gritter.add
          time: 5000
          text: 'Please select Checklist to maintain'
          class_name: "alert alert-danger"
    return false

  equipment_modal.on 'hidden.bs.modal', (e) ->
    current_equipment_id = -1
