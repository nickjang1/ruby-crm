$ ->
  return unless $('body').hasClass('equipment-setup-page')

  equipment_types = []
  $equipment_type_template = $('#equipment-type-template')
  $checklist_group_template = $('#checklist-group-template')
  $checklist_item_template = $('#checklist-item-template')
  $equipment_template = $('#equipment-template')
  $equipment_type_listing = $('#equipment-types > .items-listing')
  $equipment_type_modal = $('#equipment-type-modal')
  $equipment_modal = $('#equipment-modal')
  $equipment_form_template = $('#equipment-form-template').html()
  $equipment_type_form_template = $('#equipment-type-form-template').html()
  $checklist_item_modal = $('#equipment-checklist-item-modal')
  $checklist_item_form_template = $('#equipment-checklist-item-form-template').html()
  current_equipment_type = {}
  current_checklist_group = {}
  current_equipment_type_id = -1
  current_equipment = {}
  PANEL_CLASSES = ['panel-inverse', 'panel-success', 'panel-danger', 'panel-primary', 'panel-teal', 'panel-info']

  $('#equipment-checklist-item-form').preventDoubleSubmission()

  $.ajax(
    Routes.maintenance_equipment_types_path(),
    dataType: 'JSON',
    type: 'GET'
  ).done((types) ->
    equipment_types = types
    build_equipment_types(equipment_types)

    $equipment_type_listing.sortable
      axis: 'y'
      handle: '.area-sort-handle'
      cursor: 'ns-resize'
      update: (event, ui) ->
        item_id = ui.item.data('id')
        $.ajax
          type: 'PUT'
          url: Routes.maintenance_equipment_type_path(item_id)
          dataType: 'json'
          data:
            equipment_type:
              row_order_position: ui.item.index()

  )

  xeditable_options =
    params: (params)->
      {checklist_item: {name: params.value}}
    validate: (val)->
      return 'This field is required' if $.trim(val) is ''
    success: (response, newValue) ->
      type_id = $(@).parents('form').data('type-id')
      group_id = $(@).parents('form').data('group-id')
      for type in equipment_types
        if type.id == type_id
          for group in type.checklist_groups
            if group.id == group_id
              index = group.checklist_items.map((item) -> item.id).indexOf(response.id)
              group.checklist_items.splice(index, 1, response)

  update_equipment_type_panel = (type) ->
    $type = $(".equipment-type-item[data-id=\"#{type.id}\"]")
    if type.active_equipments && type.active_equipments.length > 0
      $type.find('.no-equipments').addClass('hidden')
      $type.find('.panel-equipments .panel-toolbar').removeClass('hidden')
    else
      $type.find('.no-equipments').removeClass('hidden')
      $type.find('.panel-equipments .panel-toolbar').addClass('hidden')
    if type.checklist_groups && type.checklist_groups.length > 0
      $type.find('.no-checklist-groups').addClass('hidden')
      $type.find('.panel-checklist-groups .panel-toolbar').removeClass('hidden')
    else
      $type.find('.no-checklist-groups').removeClass('hidden')
      $type.find('.panel-checklist-groups .panel-toolbar').addClass('hidden')
    $type.find('.items-listing').sortable
      axis: 'y'
      handle: '.checklist-sort-handle'
      cursor: 'ns-resize'
      update: (event, ui) ->
        equipment_type_id = $(ui.item).parents('.equipment-type-item').data('id')
        checklist_group_id = ui.item.data('id')
        url = Routes.maintenance_equipment_type_equipment_checklist_item_path(equipment_type_id, checklist_group_id)

        $.ajax(
          url: url,
          type: 'PUT',
          data:
            checklist_item:
              row_order_position: ui.item.index()
        ).done((record) ->
          console.log(record)
        )
  update_panel_colors = () ->
    for type, index in equipment_types
      $panel = $equipment_type_listing.find(".equipment-type-item[data-id=\"#{type.id}\"]")
      $panel.attr('class', "panel equipment-type-item #{PANEL_CLASSES[index % 6]}")

  build_equipment_type = (record) ->
    index = equipment_types.map((type) -> type.id).indexOf(record.id)
    record.panel_class = PANEL_CLASSES[index % 6]
    for group in record.checklist_groups
      group.item_count = group.checklist_items.length
    $rendered = $(Mustache.render($equipment_type_template.html(), record, checklist_group: $checklist_group_template.html(), active_equipment: $equipment_template.html()))
    $rendered

  build_checklist_group = (record) ->
    record.item_count = record.checklist_items.length
    Mustache.render($checklist_group_template.html(), record)

  build_equipment = (record) ->
    $rendered = $(Mustache.render($equipment_template.html(), record))
    $rendered

  build_checklist_item = (record) ->
    $rendered = $(Mustache.render($checklist_item_template.html(), record))
    $rendered.find('.x-editable').editable(xeditable_options)
    $rendered

  build_equipment_types = (types) ->
    for type, index in types
      rendered = build_equipment_type(type)
      $equipment_type_listing.append(rendered)
      update_equipment_type_panel(type)
      update_equipment_type_info type.id
      rendered.find('.equipments-listing').sortable
        axis: 'y'
        handle: '.equipment-sort-handle'
        cursor: 'ns-resize'
        update: (event, ui) ->
          equipment_type_id = $(ui.item).parents('.equipment-type-item').data('id')
          url = Routes.maintenance_equipment_path($(ui.item).data('id'), equipment_type_id: equipment_type_id)
          $.ajax
            type: 'PUT'
            url: url
            dataType: 'json'
            data:
              equipment:
                row_order_position: ui.item.index()

  toggle_type_form_modal = (record, status) ->
    if status == 'show'
      if record.attachment? && record.attachment.file?
        record.attachment.file.name = record.attachment.file.url.substring(record.attachment.file.url.lastIndexOf('/')+1)
      $html = $(Mustache.render($equipment_type_form_template, record))
      $html.find('button[type=submit]').removeAttr('disabled')
      $equipment_type_modal.find('.modal-dialog').html($html)
    $equipment_type_modal.modal(status)

  toggle_equipment_modal = (record, status) ->
    if status == 'show'
      if record.attachment? && record.attachment.file?
        record.attachment.file.name = record.attachment.file.url.substring(record.attachment.file.url.lastIndexOf('/')+1)
      $html = $(Mustache.render($equipment_form_template, record))
      $html.find('input[type=submit]').removeAttr('disabled')
      $html.find('.datepicker').datepicker({dateFormat: 'yy-mm-dd'})
      $html.find('input.numeric-input').numeric()
      $equipment_modal.find('.modal-dialog').html($html)
    $equipment_modal.modal(status)

  toggle_group_form_modal = (record, status) ->
    if status == 'show'
      $html = $(Mustache.render($checklist_item_form_template, record, checklist_item: $checklist_item_template.html()))
      $html.find('#frequency').val(record.frequency) if record.frequency
      $html.find('.x-editable').editable(xeditable_options)
      $checklist_item_modal.find('.modal-dialog').html($html)
      $checklist_item_modal.find('.items-listing').sortable
        axis: 'y'
        handle: '.item-sort-handle'
        cursor: 'ns-resize'
        update: (event, ui) ->
          $.ajax
            type: 'PUT'
            url: ui.item.find('a.checklist-item-name').data('url')
            dataType: 'json'
            data:
              checklist_item:
                row_order_position: ui.item.index()
          .done (res) ->
            type_index = _.findIndex(equipment_types, (e) -> e.id == res.equipment_type_id)
            group_index = _.findIndex(equipment_types[type_index].checklist_groups, (e) -> e.id == res.group_id)
            item_index = _.findIndex(equipment_types[type_index].checklist_groups[group_index].checklist_items, (e) -> e.id == res.id)
            equipment_types[type_index].checklist_groups[group_index].checklist_items[item_index] = res
            items = _.sortBy(equipment_types[type_index].checklist_groups[group_index].checklist_items, 'row_order')
            equipment_types[type_index].checklist_groups[group_index].checklist_items = items
            update_checklist_item_order($(ui.item).parent())
      update_checklist_item_order($html.find('.items-listing'))

    $checklist_item_modal.modal(status)

  update_checklist_item_order = ($listing) ->
    _.each $listing.find('.checklist-item .count'), (e, i) -> $(e).text(i+1)

  updateEquipmentTypeDetail= (equipment_type_id) ->
    equipment_type = _.find(equipment_types, (e) -> e.id == equipment_type_id)
    equipment_type.
    _.each $listing.find('.checklist-item .count'), (e, i) -> $(e).text(i+1)

  $('a.add-equipment-type').on 'click', (e) ->
    toggle_type_form_modal({}, 'show')
    new_record = true
    return false

  $('body').on 'submit', '#equipment-type-form', (e) ->
    e.preventDefault()
    $form = $(@)
    if $form.parsley().validate()
      $form.find('button[type=submit]').attr('disabled', 'disabled')
      data = new FormData()
      name = $form.find('#equipment-type-name').val()
      instruction = $form.find('#instruction-description').val()
      data.append 'equipment_type[name]', name
      new_record = $.isEmptyObject(current_equipment_type)
      data.append 'equipment_type[instruction]', instruction
      files = $form.find('#attachment')[0].files
      $form.find('input[type=submit]').attr('disabled', 'disabled')
      if files.length > 0
        data.append 'equipment_type[attachment_attributes][file]', files[0]
      unless new_record || !current_equipment_type.attachment?
        data.append 'equipment_type[attachment_attributes][id]', current_equipment_type.attachment.id

      $.ajax(
        url: if new_record then Routes.maintenance_equipment_types_path() else Routes.maintenance_equipment_type_path(current_equipment_type.id),
        type: if new_record then 'POST' else 'PUT',
        data: data,
        processData: false,
        contentType: false,
        cache: false
      ).done((record) ->
        if new_record
          equipment_types.push record
          rendered = build_equipment_type(record)
          $equipment_type_listing.append(rendered)
        else
          index = equipment_types.map((type) -> type.id).indexOf(record.id)
          equipment_types.splice index, 1, record
          $(".equipment-type-item[data-id=\"#{record.id}\"]").find('a.equipment-type-name').text(record.name)
        current_equipment_type = {}
        toggle_type_form_modal({}, 'hide')
        update_equipment_type_panel(record)
      ).fail((xhr) ->
        $.gritter.add
          time: 5000
          text: xhr.responseText
          class_name: "alert alert-danger"
      )

  update_equipment_type_info = (equipment_type_id) ->
    equipment_type = _.find(equipment_types, (e) -> e.id == equipment_type_id)
    detail = " [#{equipment_type.checklist_groups.length} checklists, #{equipment_type.active_equipments.length} units]"
    $(".equipment-type-item[data-id=#{equipment_type_id}] .equipment-type-info").text(detail)

  $('body').on 'submit', '#equipment-checklist-item-form', (e) ->
    e.preventDefault()
    $form = $(@)
    $listing = $(".equipment-type-item[data-id=\"#{current_equipment_type_id}\"]").find('.items-listing')
    if $form.parsley().validate()
      $form.find('button[type=submit]').attr('disabled', 'disabled')
      name = $form.find('#checklist-group-name').val()
      tools_required = $form.find('#tools-required').val()
      frequency = $form.find('#frequency').val()
      new_record = $.isEmptyObject(current_checklist_group)
      url = if new_record
              Routes.maintenance_equipment_type_equipment_checklist_items_path(current_equipment_type_id)
            else
              Routes.maintenance_equipment_type_equipment_checklist_item_path(current_equipment_type_id, current_checklist_group.id)

      $.ajax(
        url: url,
        type: if new_record then 'POST' else 'PUT',
        data:
          checklist_item:
            name: name
            tools_required: tools_required
            frequency: frequency
      ).done((record) ->
        if new_record
          rendered = build_checklist_group(record)
          for type in equipment_types
            if type.id == current_equipment_type_id
              type.checklist_groups.push record
              update_equipment_type_panel(type)
          $listing.append(rendered)
          $form.attr('data-group-id', record.id)
          $form.attr('data-type-id', record.equipment_type_id)
          $('#checklist-items-panel').removeClass('hidden')
          update_equipment_type_info(record.equipment_type_id)
          unless record.group_id
            $form.find('.modal-title').text("Edit Checklist '#{record.name}'")
            current_checklist_group = record
        else
          for type in equipment_types
            if type.id == current_equipment_type_id
              index = type.checklist_groups.map((item) -> item.id).indexOf(record.id)
              type.checklist_groups.splice(index, 1, record)
          $(".checklist-group[data-id=\"#{current_checklist_group.id}\"]")
            .find('a.checklist-group-name')
            .html("#{record.name} (<span class='item-count'>#{record.checklist_items.length}</span> items)")
      ).fail((xhr) ->
        $.gritter.add
          time: 5000
          text: xhr.responseText
          class_name: "alert alert-danger"
      ).always( ->
        $form.find('input[type=submit]').attr('disabled', 'disabled')
      )
  $('body').on 'change keydown keyup', '#checklist-item-name', (e) ->
    if $(this).val() == ''
      $(this).parent().find('.add-item').removeClass('btn-primary')
      $(this).parent().find('.add-item').addClass('btn-default')
    else
      $(this).parent().find('.add-item').addClass('btn-primary')
      $(this).parent().find('.add-item').removeClass('btn-default')

  $('body').on 'submit', '#equipment-form', (e) ->
    e.preventDefault()
    $form = $(@)
    if $form.parsley().validate()
      $form.find('input[type=submit]').attr('disabled', 'disabled')
      data = new FormData()
      name = $form.find('#equipment-name').val()
      make = $form.find('#equipment-make').val()
      location = $form.find('#equipment-location').val()
      buy_date = $form.find('#equipment-buy-date').val()
      replacement_date = $form.find('#equipment-replacement-date').val()
      instruction = $form.find('#equipment-instruction-description').val()
      warranty = $form.find('#equipment-warranty').val()
      lifespan = $form.find('#equipment-lifespan').val()
      data.append 'equipment[name]', name
      data.append 'equipment[make]', make
      data.append 'equipment[location]', location
      data.append 'equipment[buy_date]', buy_date
      data.append 'equipment[replacement_date]', replacement_date
      data.append 'equipment[instruction]', instruction
      data.append 'equipment[warranty]', warranty
      data.append 'equipment[lifespan]', lifespan
      new_record = $.isEmptyObject(current_equipment)
      files = $form.find('#equipment-attachment')[0].files
      if files.length > 0
        data.append 'equipment[attachment_attributes][file]', files[0]
      unless new_record || !current_equipment.attachment?
        data.append 'equipment[attachment_attributes][id]', current_equipment.attachment.id

      url = if new_record
              Routes.maintenance_equipments_path(equipment_type_id: current_equipment_type.id)
            else
              Routes.maintenance_equipment_path(current_equipment.id, equipment_type_id: current_equipment_type.id)

      $.ajax(
        url: url,
        type: if new_record then 'POST' else 'PUT',
        data: data,
        processData: false,
        contentType: false,
        cache: false
      ).done((record) ->
        if new_record
          rendered = build_equipment(record)
          $(".equipment-type-item[data-id=\"#{current_equipment_type.id}\"]").find('.equipments-listing').append(rendered)
          index = equipment_types.map((type) -> type.id).indexOf(record.equipment_type_id)
          equipment_types[index].active_equipments = [] unless equipment_types[index].active_equipments?
          equipment_types[index].active_equipments.push record
          update_equipment_type_panel(equipment_types[index])
          update_equipment_type_info(current_equipment_type.id)
        else
          index = equipment_types.map((type) -> type.id).indexOf(record.equipment_type_id)
          equipment_index = equipment_types[index].active_equipments.map((item) -> item.id).indexOf(record.id)
          equipment_types[index].active_equipments.splice equipment_index, 1, record
          $(".equipment-item[data-id=\"#{record.id}\"]").find('a.equipment-name').text("#{record.name} (#{record.location})")
        current_equipment_type = {}
        current_equipment = {}
        toggle_equipment_modal({}, 'hide')
      ).fail((xhr) ->
        $.gritter.add
          time: 5000
          text: xhr.responseText
          class_name: "alert alert-danger"
      ).always( ->
        $form.find('input[type=submit]').removeAttr('disabled')
      )

  $('body').on 'change', '#equipment-type-form #attachment', (e) ->
    $('#equipment-type-form #attachment-name').val($('#equipment-type-form #attachment')[0].files[0].name)
  $('body').on 'change', '#equipment-form #equipment-attachment', (e) ->
    $('#equipment-form #equipment-attachment-name').val($('#equipment-form #equipment-attachment')[0].files[0].name)

  $('body').on 'click', 'a.equipment-type-name', (e) ->
    id = $(@).parents('.equipment-type-item').data('id')
    for type in equipment_types
      if type.id == id
        current_equipment_type = type
    toggle_type_form_modal(current_equipment_type, 'show')
    return false

  $('body').on 'click', 'a.equipment-name', (e) ->
    id = $(@).parents('.equipment-type-item').data('id')
    item_id = $(@).parents('.equipment-item').data('id')
    for type in equipment_types
      if type.id == id
        current_equipment_type = type
    for equipment in current_equipment_type.active_equipments
      if equipment.id == item_id
        current_equipment = equipment
    current_equipment.type_name = current_equipment_type.name
    toggle_equipment_modal(current_equipment, 'show')
    return false

  $('body').on 'click', 'a.checklist-group-name', (e) ->
    current_equipment_type_id = $(@).parents('.equipment-type-item').data('id')
    id = $(@).parents('.checklist-group').data('id')
    type = $.grep(equipment_types, (type) ->
      type.id == current_equipment_type_id
    )[0]
    current_checklist_group = $.grep(type.checklist_groups, (item) ->
      item.id == id
    )[0]
    current_checklist_group.type_name = type.name
    current_checklist_group.type_id = type.id
    if current_checklist_group.checklist_items
      _.each current_checklist_group.checklist_items, (item, index) ->
        item.type_id = type.id
        item.update_url = Routes.maintenance_equipment_type_equipment_checklist_item_path(type.id, item.id)
    toggle_group_form_modal(current_checklist_group, 'show')
    return false

  $('body').on 'dialog.confirmed', 'a.delete-attachment', (e) ->
    $this = $(@)
    type = $this.data('type')
    id = $this.data('id')
    type_id = $this.data('type-id')
    attachment_id = $this.parents('.attachment-info').data('id')
    url = if type == 'equipment_type'
            Routes.maintenance_equipment_type_path(id)
          else if type == 'equipment'
            Routes.maintenance_equipment_path(id, equipment_type_id: type_id)
    data = {}
    data[type] = {attachment_attributes: {_destroy: 1, id: attachment_id}}
    $.ajax(
      url: url,
      type: 'PUT',
      data: data
    ).done((record) ->
      if type == 'equipment_type'
        for etype in equipment_types
          if etype.id == id
            etype.attachment = {}
      else
        for etype in equipment_types
          for equipment in etype.active_equipments
            if equipment.id == record.id
              equipment.attachment = {}
      $this.parents('.attachment').find('#attachment-name').attr('placeholder', '')
      $this.parents('.attachment-info').remove()
    )
    return false

  $('body').on 'click', '.equipment-type-item > .panel-heading', (e) ->
    if $(e.target).hasClass('panel-title')
      $(@).parent().find('.panel-collapse').collapse('toggle')
      $(@).find('.equipment-type-toggler').toggleClass('collapsed')
      return false

  $('body').on 'dialog.confirmed', 'a.equipment-type-delete', (e) ->
    id = $(@).parents('.equipment-type-item').data('id')
    $.ajax(
      url: Routes.maintenance_equipment_type_path(id)
      type: 'DELETE'
    ).done((id) ->
      $(".equipment-type-item[data-id=\"#{id}\"]").remove()
      equipment_types = $.grep(equipment_types, (type) ->
        type.id != id
      )
      update_panel_colors()
    )
    return false

  $('body').on 'dialog.confirmed', 'a.equipment-delete', (e) ->
    type_id = $(@).parents('.equipment-type-item').data('id')
    id = $(@).parents('.equipment-item').data('id')
    $.ajax(
      url: Routes.maintenance_equipment_path(id, equipment_type_id: type_id)
      type: 'DELETE'
    ).done((id) ->
      $(".equipment-item[data-id=\"#{id}\"]").remove()
      for type in equipment_types
        if type_id == type.id
          type.active_equipments = $.grep(type.active_equipments, (item) -> item.id != id)
          update_equipment_type_panel(type)
      update_equipment_type_info type_id
    )
    return false

  $('body').on 'dialog.confirmed', 'a.checklist-group-delete', (e) ->
    equipment_type_id = $(@).parents('.equipment-type-item').data('id')
    id = $(@).parents('.checklist-group').data('id')
    $.ajax(
      url: Routes.maintenance_equipment_type_equipment_checklist_item_path(equipment_type_id, id)
      type: 'DELETE'
    ).done((id) ->
      $(".checklist-group[data-id=\"#{id}\"]").remove()
      for type in equipment_types
        if type.id == equipment_type_id
          type.checklist_groups = $.grep(type.checklist_groups, (item) -> item.id != id)
          update_equipment_type_panel(type)
      update_equipment_type_info equipment_type_id
    )
    return false

  $('body').on 'dialog.confirmed', 'a#remove-equipment', (e) ->
    type_id = $(@).data('type-id')
    id = $(@).data('id')
    $.ajax(
      url: Routes.maintenance_equipment_path(id, equipment_type_id: type_id)
      type: 'PUT'
      data:
        equipment:
          removed: true
    ).done((record) ->
      $(".equipment-item[data-id=\"#{record.id}\"]").remove()
      for type in equipment_types
        if type_id == type.id
          type.active_equipments = $.grep(type.active_equipments, (item) -> item.id != id)
          update_equipment_type_panel(type)
      toggle_equipment_modal({}, 'hide')
    )
    return false

  $('body').on 'dialog.confirmed', 'a.checklist-item-delete', (e) ->
    type_id = $(@).parents('form').data('type-id')
    group_id = $(@).parents('form').data('group-id')
    id = $(@).parents('.checklist-item').data('id')
    $checklist_listing = $(@).parents('.items-listing')
    $.ajax(
      url: Routes.maintenance_equipment_type_equipment_checklist_item_path(type_id, id)
      type: 'DELETE'
    ).done((id) ->
      $(".checklist-item[data-id=\"#{id}\"]").remove()
      for type in equipment_types
        if type.id == type_id
          for group in type.checklist_groups
            if group.id == group_id
              group.checklist_items = $.grep group.checklist_items, (item) -> item.id != id
              group.item_count -= 1
              $(".checklist-group[data-id=\"#{group_id}\"]").find('span.item-count').text(group.checklist_items.length)
              update_checklist_item_order($checklist_listing)

    )
    return false

  $checklist_item_modal.on 'hidden.bs.modal', (e) ->
    current_checklist_group = {}

  $equipment_type_modal.on 'hidden.bs.modal', (e) ->
    current_equipment_type = {}
    current_equipment_type_id = {}

  $equipment_modal.on 'hidden.bs.modal', (e) ->
    current_equipment_type = {}
    current_equipment_type_id = {}
    current_equipment = {}

  $('body').on 'change keydown keyup', '#tools-required, #checklist-group-name, #frequency', (e) ->
    $('#checklist-group-form-submit').removeAttr('disabled')

  $('body').on 'click', '.add-group', (e) ->
    current_equipment_type_id = $(@).parents('.equipment-type-item').data('id')
    for type in equipment_types
      if type.id == current_equipment_type_id
        current_equipment_type = type
    toggle_group_form_modal({type_name: current_equipment_type.name}, 'show')
    return false

  $('body').on 'click', '.add-equipment', (e) ->
    id = $(@).parents('.equipment-type-item').data('id')
    for type in equipment_types
      if type.id == id
        current_equipment_type = type
    toggle_equipment_modal({type_name: current_equipment_type.name}, 'show')
    return false

  add_item = (e) ->
    type_id = $(e.target).parents('form').data('type-id')
    group_id = $(e.target).parents('form').data('group-id')
    name = $('#checklist-item-name').val()
    $('.name-error').remove()
    unless name
      $(e.target).parents('.input-group').after('<ul class="parsley-errors-list filled name-error"><li class="parsley-required">Name is required.</li></ul>')
      return false

    $.ajax(
      url: Routes.maintenance_equipment_type_equipment_checklist_items_path(type_id),
      type: 'POST',
      data:
        checklist_item:
          name: name
          group_id: group_id
    ).done((record) ->
      record.update_url = Routes.maintenance_equipment_type_equipment_checklist_item_path(type_id, record.id)
      group = null
      for type in equipment_types
        if type.id == type_id
          for group in type.checklist_groups
            group.checklist_items = [] unless group.checklist_items
            if group.id == group_id
              group.item_count += 1
              group.checklist_items.push record
              $(".checklist-group[data-id=\"#{group_id}\"]").find('span.item-count').text(group.checklist_items.length)
      rendered = build_checklist_item(record)
      $('#checklist-items-panel').find('.items-listing').append(rendered)
      update_checklist_item_order($('#checklist-items-panel').find('.items-listing'))

      $('#checklist-item-name').val('')
      $('#checklist-item-name').removeAttr('disabled')
      $('#checklist-item-name').focus()
    ).fail((xhr) ->
      $.gritter.add
        time: 5000
        text: xhr.responseText
        class_name: "alert alert-danger"
    )

  $('body').on 'keypress', '#checklist-item-name', (e) ->
    if e.which == 13
      $(@).attr('disabled', 'disabled')
      add_item(e)

  $('body').on 'click', '.add-item', (e) ->
    add_item(e)
    return false