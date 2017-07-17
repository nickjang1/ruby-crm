roomSetupPage = ->
  return unless $('body').hasClass('room-setup-page')

  floor_template = $('#room-floor-template').html()
  floors_rows = $('#floors-data tbody.floors-rows')
  new_rooms = []
  delete_link = ''
  isInitialLoad = true

  # attach x-editable plugin to room_tags
  makeRoomNamesEditable = (room_tag)->
    room_tag.off('click')
    url = if isInitialLoad || room_tag.hasClass('created') then Routes.maintenance_room_path( room_tag.data('value')) else ''
    room_tag.editable(url: url, container: 'body', title: 'Room number',inputclass: 'room-number-editable', send: 'always', success: (x, newVal)->)
    room_tag.editable('setValue', $(room_tag).text())

  $('body').on 'keypress', '.editable-input input.room-number-editable', (e) ->
    charCode = e.charCode || e.which
    if charCode == 45 || charCode == 35
      $.gritter.add
        text: "You can not enter '#' or '-' for room number."
        class_name: "alert alert-warning"
      e.preventDefault()

  recalculateTotalRoomsCount = ->
    result = 0
    $('#floors-data .total-rooms').each -> result += $(@).text() * 1
    $('#total-room-count').text(result)

  makeRoomInputSelectized = (input, rooms)->
    $input = input.selectize
      plugins: ['no-delete']
      delimiter: ','
      persist: false
      create: (tag_value, x) -> { value: tag_value, text: tag_value }
      render: item: (item, escape)-> "<div class='item'>#{item.text}</div>"
      onItemAdd: (value, $item)->
        $('#save-rooms-btn').attr('disabled', false) unless isInitialLoad
        input.closest('tr').find('td.total-rooms').text(input[0].selectize.items.length)
        makeRoomNamesEditable( $item )
        recalculateTotalRoomsCount()

    $.each rooms, (i, room)->
      input[0].selectize.addOption
        text: room.room_number
        value: room.id
      input[0].selectize.addItem room.id

    room_tags = $input.siblings('.selectize-control').find('.selectize-input').off('mousedown').find('> div')
  #makeRoomNamesEditable(room_tags)

  loadRooms = ->
    $.ajax(Routes.maintenance_rooms_path(), {type: 'GET', dataType: 'json'}).done (rooms_by_floor)->
      floors_rows.html("")

      $(rooms_by_floor).each ->
        rendered_floor = $(Mustache.render(floor_template, {floor: @.floor, room_count: @.rooms.length} ))
        makeRoomInputSelectized(rendered_floor.find('input.selectized-control'), @.rooms, true)
        floors_rows.append(rendered_floor)
      isInitialLoad = false
      $('#save-rooms-btn').attr('disabled', true)
      $('.selectized-control .item').addClass('created')
      recalculateTotalRoomsCount()

  loadRooms() # make initial rooms load

  $('#save-rooms-btn').on 'click', (e) ->
    $('#saving-rooms-indicator').addClass 'show'
    rooms = $('.selectize-control .selectize-input > div:not(.created)')
    roomsData = rooms.map -> { floor: $(@).closest('tr').data('floor'), room_number: $(@).data('value') }
    $.ajax(
      url: Routes.maintenance_rooms_path()
      type: 'POST'
      data: rooms: roomsData.toArray()
    ).done( (response)->

      $('#save-rooms-btn').attr('disabled', 'disabled')
      $.each response, (i, room)->
        tmpTag = $(".selectize-control div[data-value='#{room.room_number}']")
        input = tmpTag.closest('.selectize-control').siblings('input')
        input[0].selectize.updateOption(room.room_number, {value: room.id, text: room.room_number})

      rooms = $('.selectize-control .selectize-input > div:not(.created)')
      rooms.addClass('created')
      rooms.each -> makeRoomNamesEditable( $(@) )
    ).always( ->
      $('#saving-rooms-indicator').removeClass 'show'
    )
    return false

  $('.add-floor').on 'click', (e) ->
    last_floor_number = floors_rows.addBack().find('> tr:last-child').data('floor') or 0
    new_floor = Mustache.render(floor_template, {floor: last_floor_number + 1, room_count: 0})
    floors_rows.append(new_floor)
    enter_rooms_input = floors_rows.addBack().find('> tr:last-child input.selectized-control')
    makeRoomInputSelectized(enter_rooms_input, [], false)
    enter_rooms_input.siblings('.selectize-control').find('.selectize-input').off('mousedown')

  #
  #  Checklist Items:
  #
  checklist_tmpl = $('#checklist-area-item-template').html()
  checklist_subitem_tmpl = $('#checklist-subcategory-template').html()
  checklist_items = $('#checklist-items')
  xeditable_options =
    params: (params)->
      {checklist_item: {name: params.value}}
    validate: (val)->
      return 'This field is required' if $.trim(val) is ''

  $.ajax(Routes.maintenance_checklist_items_path(), { dataType: 'json' }).done (categories)->
    $(categories).each ->
      rendered_area = $(Mustache.render(checklist_tmpl, @, {subcategory: checklist_subitem_tmpl} ))
      rendered_area.appendTo(checklist_items.find('> .panel-group'))

    checklist_items.find('.items-listing').sortable
      axis: "y"
      handle: '.area-sort-handle'
      cursor: "ns-resize"
      update: (event, ui) ->
        item_id = ui.item.data('id')
        item_type = ui.item.data('type')
        checklist_item_data = {}
        checklist_item_data[ui.item.data('type') + "_row_order_position"] = ui.item.index()
        $.ajax
          type: 'PATCH'
          url: Routes.maintenance_checklist_item_path(item_id)
          dataType: 'json'
          data: {checklist_item: checklist_item_data}

    checklist_items.find('a.x-editable').editable(xeditable_options)

  # add a new checklist item:
  checklist_items.on 'click', '.add-item', ->
    link = $(@)
    link_html = link.html()
    link.html(link.data('loading-text')).attr('disabled', true)
    new_item_params = {name: 'New Item', maintenance_type: 'rooms', area_id: link.data('area-id')}

    $.ajax Routes.maintenance_checklist_items_path(),
      type: 'POST', data: {checklist_item: new_item_params}
    .done (data)->
      template = if !!link.data('area-id') then checklist_subitem_tmpl else checklist_tmpl
      link.siblings('.panel-group').append(Mustache.render(template, data))
      link.siblings('.panel-group').find(':last-child a.x-editable').editable(xeditable_options)
    .always -> link.html(link_html).attr('disabled', false)

  # delete checklist item:
  checklist_items.on 'click', '.x-deleteable', ->
    delete_link = $(@)

    $('.checklist_heading').html(delete_link.data('heading'))
    $('.checklist_message').html(delete_link.data('message'))
    $('#ChecklistconfirmationDialog').modal('show')
  $('#ChecklistconfirmationDialog .confirm').on 'click', ->
    $.ajax Routes.maintenance_checklist_item_path({id: delete_link.data('checklist-id')}),
      type: 'DELETE',
    .done (data)->
      delete_link.parent().parent().parent().remove()
  $('#ChecklistconfirmationDialog .modal-close').on 'click', ->
    $('#ChecklistconfirmationDialog').modal('hide')

  #
  #  Cycles:
  #
  $start_month = $('#start-month')
  $frequency = $('#room_frequency')
  create_cycle = () ->
    start_month = $start_month.val()
    frequency = $frequency.val()
    return unless !!start_month && !!frequency
    $.ajax(
      url: Routes.maintenance_cycles_path()
      type: 'POST'
      dataType: 'json'
      data:
        start_month: start_month || 1
        frequency: frequency
        cycle_type: 'room'
    ).done((data) ->
      $.gritter.add
        time: 5000
        text: data.message
        class_name: "alert alert-success"
      $frequency.val(data.cycle.frequency_months)
      $start_month.attr('disabled', 'disabled')
      $frequency.attr('disabled', 'disabled')
    ).fail((xhr) ->
      response = $.parseJSON(xhr.responseText).error
      $.gritter.add
        time: 5000
        text: response
        class_name: "alert alert-danger"
    )

  $start_month.on 'change', (e) ->
    unless !!$start_month.val()
      $frequency.attr('disabled', 'disabled')
    else
      $frequency.removeAttr('disabled')

  $frequency.on 'change', (e) ->
    create_cycle()

  #
  # Target Inspection Percent
  #
  $inspection_percent = $('#target-inspection-field')
  $inspection_percent.on 'change', ->
    percent = $(@).val()
    $.ajax(
      dataType: 'json',
      type: 'PUT',
      url: Routes.property_path(id: $inspection_percent.data('property')),
      data:
        property:
          settings:
            target_inspection_percent: percent
    ).done((data) ->
      $.gritter.add
        time: 5000
        text: "Target Inspection Percent updated."
        class_name: "alert alert-success"
    ).fail((xhr) ->
      response = $.parseJSON(xhr.responseText)
      $.gritter.add
        time: 5000
        text: response
        class_name: "alert alert-danger"
    )

$(document).ready(roomSetupPage)
