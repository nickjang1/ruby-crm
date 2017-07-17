$ ->
  message_template = $('.message-mustache-template').html()

  addComment = (parent, message, order='asc') ->
    message.body = message.body.replace(/\n/g, "<br />")

    rendered = Mustache.render(
      message_template,
      message: message
    )
    if order == 'desc'
      parent.find('.media-list').append rendered
    else
      parent.find('.media-list').prepend rendered

    parent.find('.media-list span.no-messages').remove()

  workOrders = $('.work-orders')

  workOrders.on 'click', '.dropdown.custom', (e) ->
    e.stopPropagation()
    $this = $(this)
    $('#model-messages .messages-dropdown').attr('data-model-id', $this.data('model-id'))
    $('#model-messages .messages-dropdown').attr('data-model-number', "##{$this.data('model-number')}")

    if $(this).hasClass('open')
      $('#model-messages .dropdown-menu').css('display', 'none');
      $(this).removeClass('open')
      $(".message-dropdown-backdrop").remove(); # Remove dropdown backdrop after collapse dropdown
      return;
    else
      $('.dropdown.custom').removeClass('open')
      $(this).addClass('open')
    $(@).parents('.work-order').find('.indicator').show() if $(@).parents('.work-order').length > 0

    $.ajax(
      url: Routes.messages_path(),
      dataType: 'json',
      method: 'GET',
      data:
        model_id: $this.data('model-id')
        model_type: $this.data('model-type')
        property_id: property_id
    ).success (data) =>
      $(@).parents('.work-order').find('.indicator').hide()

      if (data.length > 0)
        $this.find('span#messages-icon').addClass('text-primary')
        $('#model-messages .dropdown-menu .media-list').html('')
        $.each data, (i, message) ->
          addComment($('#model-messages .dropdown-menu'), message, 'desc')
      else
        $('#model-messages .dropdown-menu .media-list').html("<div class='text-center'><span class='toolbar-label semibold'>No comments present for this request</span></div>")
      $('#model-messages').css('position': 'absolute')

      if $this.hasClass('no-shuffled') # if chat icon is on no-shuffled parent element(if it doesn't have transform attribute)
        right = $this.offset().left - $("#model-messages-dropdown").width();
        $('#model-messages').css(
          left: "#{Math.max(30, right + 80)}px"
          top: "#{$this.offset().top + 30}px"
        )
      else
        left = $this.offset().left - $this.position().left - 10
        maxLeft = $(window).width() - $("#model-messages-dropdown").width()
        if maxLeft < left
          left = maxLeft - 30
        $('#model-messages').css(
          left: "#{left}px"
          top: "#{$this.offset().top + 30}px"
        )

      $('#model-messages .dropdown-menu .count').text("(#{data.length})")
    .done (data) ->
      $('#model-messages .dropdown-menu').css('display', 'block');
      $('<div class="message-dropdown-backdrop fade in"></div>').appendTo(document.body) # Show backdrop on the back of

  $(document).on "click", '.add-work-order', (e) ->
    e.preventDefault();
    $this = $(@)
    $this.attr('disabled', 'disabled')
    description = $("<div>#{$this.data("description") || ""}</div>").text()
    room_number = $this.data("room-number") || ""
    $('#wo-modal').load Routes.new_maintenance_work_order_path(property_id: property_id), ->
      $(@).find('input[name="maintenance_work_order[due_to_date]"]').datepicker(minDate: new Date())
      if !!description
        $(@).find("textarea[name='maintenance_work_order[description]']").val(description)
      if !!room_number
        $(@).find(maintainable_type_selector).val("Maintenance::Room")
      $(@).find(maintainable_type_selector).trigger('change')
      if !!room_number
        $(@).find("[data-location-type='Maintenance::Room']")
            .find("select[name='maintenance_work_order[maintainable_id]']")
            .find("option:contains('#{room_number}')").first().attr("selected", true)
      $(@).modal()
      $(@).data('status', 'Open')
      $(@).find('select[name="maintenance_work_order[status]"]').trigger('change')
      $this.removeAttr('disabled')
      applyPermissions($(@).find('form.detail-form'), false)
      makeFormAjaxy( $(@).find('form.detail-form'), 'POST', (response)->
        newItem = $(response)
        workOrders.append(newItem).shuffle('appended', newItem)
        getFilterOptions()

        if window.workOrderSource
          window.workOrderSource.trigger("work_order_created", $(response).data("wo-id"))
      )

  submitForm = (form, method, onSubmitSuccess) ->
    formData = new FormData($(form)[0])

    # Check if image file field is empty
    form.find("input[type='file']").each (i, e) ->
      if $(e).parent().parent().hasClass('empty')
        formData.append("maintenance_work_order[attachments_attributes][#{i}][_destroy]", true)

    $.ajax(form.prop('action') + "?property_id=#{property_id}", data: formData, type: method, contentType: false, processData: false)
    .done (response)-> onSubmitSuccess(response) if !!onSubmitSuccess
    .error (xhr, ajaxOptions, thrownError) ->
      if xhr.status == 403
        $.gritter.add(text: xhr.responseText, class_name: "alert alert-danger")
      else
        $.gritter.add(text: "Error occurred while sending request. Please try again later", class_name: "alert alert-danger")
    .always -> form.find('button[type="submit"]').prop('disabled', false)

  $('body').on 'dialog:confirmed', '.work-order', (e) ->
    frm = $('.modal.in form')
    wo = $(@)
    submitForm(frm, 'PUT', (response) ->
      applyPermissions(frm)
      $('.modal.in').data('status', _.startCase(frm.find('.status').val()))
      $.gritter.add(text: "WO ##{wo.data('wo-id')} Reopened", class_name: "alert alert-success")
      workOrders.shuffle('remove', wo)
      updatedItem = $(response)
      workOrders.append(updatedItem).shuffle('appended', updatedItem)
    )

  makeFormAjaxy = (form, method, onSubmitSuccess, wo)->
    form.on('submit', (e)-> e.preventDefault()).parsley().subscribe 'parsley:form:validate', (formInstance) ->
      formInstance.submitEvent.preventDefault()
      if formInstance.isValid()
        formElement = formInstance.$element
        formElement.find('button[type="submit"]').prop('disabled', true)

        initialStatus = form.closest('.modal').data('status')
        currentStatus = form.find('select[name="maintenance_work_order[status]"] option:selected').text()
        statusChangedFromClosed = initialStatus is 'Closed' && currentStatus isnt 'Closed'

        if statusChangedFromClosed # && !confirm('Do you want to reopen the closed work order?')
          formElement.find('button[type="submit"]').prop('disabled', false)
          showConfirmationDialog('Do you want to reopen the closed work order?', wo)
          return false
        if initialStatus isnt 'Closed' && currentStatus is 'Closed'
          formElement.find('button[type="submit"]').prop('disabled', false)
          confirmDialog = bootbox.dialog
            title: "Do you want to close WO ##{wo.data('wo-id')}?",
            message: $('#closing-confirmation').html(),
            className: 'closing-confirmation-modal'
            show: false
            buttons:
              danger:
                label: 'Cancel',
                className: 'btn-default'
              success:
                label: 'Close WO',
                className: 'btn-success',
                callback: (e) ->
                  $modal = $('.closing-confirmation-modal')
                  $modal.find('form').parsley().validate()
                  if $modal.find('form').parsley().isValid()
                    durationType = $modal.find('input.duration-type').is(':checked')
                    minutes =
                      if durationType
                        $modal.find('.duration').val() * 60
                      else
                        $modal.find('.duration').val()
                    formElement.find('input[name="maintenance_work_order[closing_comment]"]').val($modal.find('#closing_comment').val())
                    formElement.find('input[name="maintenance_work_order[duration]"]').val(minutes)
                    submitForm(formElement, method, (response)->
                      formElement.closest('.modal').modal('hide')
                      onSubmitSuccess(response)
                    )
                  else
                    return false
          , (result) ->
          confirmDialog.on 'shown.bs.modal', ->
            $('.duration').numeric(decimalPlaces: 2)
            $('.closing-confirmation-modal form').parsley()
            switchery = new Switchery(
              $('.closing-confirmation-modal .duration-type').get(0),
              {className: 'switch', color: '#00b1e1', secondaryColor: '#ed5466'}
            )
            $('.closing-confirmation-modal .duration-type').trigger('change')
            $(@).find("#closing_comment").val('')
          confirmDialog.modal('show')
          return false

        submitForm(formElement, method, (response)->
          formElement.closest('.modal').modal('hide')
          onSubmitSuccess(response)
        )

  maintainable_type_selector = 'select[name="maintenance_work_order[maintainable_type]"]'
  $('body').on 'change', maintainable_type_selector, ->
    maintainable_type = $(@).val()
    $(@).closest('form').find("div[data-location-type]").addClass('hidden').find(':input').prop('disabled', true)
    $(@).closest('form').find("div[data-location-type='#{ maintainable_type }']").find(':input').prop('disabled', false)
    maintainable_select = $(@).closest('form').find("div[data-location-type='#{ maintainable_type }']").removeClass('hidden').find('select')
    maintainable_select.prop('disabled', false)
    $('#public-area-checklist-item option:first-child').attr("selected", "selected")

  checklist_item_selector = "#public-area-checklist-item"
  $('body').on 'change', '#maintenance_work_order_maintainable_id', ->
    public_area_id = parseInt($(@).find('option:selected').val())
    checklists = _.map(_.filter(public_area_checklists, (e) -> e[2] == public_area_id), (checklist) -> "<option value='#{checklist[0]}'>#{checklist[1]}</option>")
    $('#public-area-checklist-item').html("<option>Select checklist item</option>#{checklists.join('')}")

  $('body').on 'change', 'select[name="maintenance_work_order[status]"]', (e) ->
    form = $('#new-wo-form')
    initialStatus = form.closest('.modal').data('status')
    currentStatus = form.find('select[name="maintenance_work_order[status]"] option:selected').text()
    newWorkOrder = form.data('new-wo')
    statusChangedFromClosed = initialStatus is 'Closed' && currentStatus isnt 'Closed'
    if initialStatus is 'Closed' && currentStatus is 'Closed'
      form.find('button[type="submit"]').addClass('hidden')
    if newWorkOrder
      form.find('button[type="submit"]').text('Create WO')
    else if statusChangedFromClosed
      form.find('button[type="submit"]').removeClass('hidden')
      form.find('button[type="submit"]').text('Reopen WO')
    else
      form.find('button[type="submit"]').text(buttonText[currentStatus])

  applyPermissions = (form, edit = true)->
    form.find(':input:not(.submit)').prop('disabled', false)
    woInitillyClosed = form.data('wo-closed')
    if woInitillyClosed && form.find('.status').val() is "closed"
      userPermittedToEditClosedWo = form.data('user-permitted-to-edit-closed-wo')
      form.find(':input').attr('disabled', true)
      form.find('.status-input, .submit').attr('disabled', false) if userPermittedToEditClosedWo
    else
      $(maintainable_type_selector).trigger('change')
      form.find('.locked-for-editing').prop('disabled', true) if edit

      form.find('.priority').attr('disabled', !form.data('permitted-priority'))
      form.find('.status').attr('disabled', !form.data('permitted-status'))
      form.find('.assigned-to-id').attr('disabled', !form.data('permitted-assigned-to-id'))
      form.find('.due-to-date').attr('disabled', !form.data('permitted-due-to-date'))

  $('body').click (e) ->
    $('#model-messages .dropdown-menu').css('display', 'none')
    $(".message-dropdown-backdrop").remove();

  property_id = current_property_id
  $propertiesFilter = $('#wo-properties')
  statusFilter = 'active'

  filtered_priorities = []
  filtered_statuses = []
  filtered_wo_types = []
  filtered_assigned_users = []
  filtered_opened_users = []
  selectedIndex = 0
  searchString = ''
  current_user_grouping = ''
  filterDateRange = new DateRange('week')
  filterDateRange.from = moment().subtract(6, 'days')
  filterDateRange.to = moment()
  buttonText = {
    'Open': 'Update WO',
    'In Progress': 'Start Working',
    'Closed': 'Close WO'
  }

  if $('body').hasClass('work-orders-comment')
    $('#model-messages .dropdown-toggle').css('display', 'none')

#  return unless $('body').hasClass('work-orders-page')

  searchFilter = ($wo) ->
    searchConditions = _.compact($.trim(searchString).toLowerCase().replace(/\s+/, ' ').split(' '))
    regExString = ""
    for word in searchConditions
      regExString += "(?=.*#{word})"
    searchRegEx = new RegExp(regExString + '.+')
    if searchConditions.length > 0
      searchRegEx.test [$wo.data('wo-id').toString(), $wo.find('.location-name').text(), $wo.find('.description').text()].join(' ').toLowerCase()
    else
      true

  getWorkOrders = ->
    property_id = $propertiesFilter.val()
    _.filter($('.work-order'), (wo) ->
      $wo = $(wo)
      $wo.data('property-id').toString() == property_id && searchFilter($wo)
    )

  getFilterOptions = =>
    wosGroups = _.map( getWorkOrders(), (wo)-> $(wo).data("groups") )
    wosGroups = _.filter(wosGroups, (wo_groups)->
      statusFilter is 'closed' && wo_groups[1] is 'Closed' || statusFilter isnt 'closed' && wo_groups[1] isnt 'Closed'
    )
    filtered_priorities = _.uniq(_.map(wosGroups, (group) -> group[0]))
    filtered_statuses =  _.uniq(_.map(wosGroups, (group) -> group[1]))
    filtered_wo_types = _.uniq(_.map(wosGroups, (group) -> group[2]))
    filtered_assigned_users = _.uniq(_.map(wosGroups, (group) -> group[3]))
    filtered_opened_users = _.uniq(_.map(wosGroups, (group) -> group[4]))
    # custom sorting for tab order
    filtered_priorities = _.sortBy(filtered_priorities, (p) -> priorities.indexOf(p))
    filtered_statuses = _.sortBy(filtered_statuses, (s) -> statuses.indexOf(s))
    filtered_wo_types = _.sortBy(filtered_wo_types, (t) -> wo_types.indexOf(t))
    filtered_assigned_users = _.sortBy(filtered_assigned_users, (a) -> _.findIndex(users, (user) -> 'assigned_' + user.id == a))
    filtered_opened_users = _.sortBy(filtered_opened_users, (a) -> _.findIndex(users, (user) -> 'opened_' + user.id ==a))

    # Refresh tabs
    setTimeout ->
      $('#wo-grouping').trigger('change')
    , 3

  $propertiesFilter.on('change', ->
    property_id = $(@).val()
    getFilterOptions()
  )

  workOrders.on 'removed.shuffle', ->
    getFilterOptions()

  $('#wo-grouping').on('change', ->
    groupBy = $(this).val()
    if current_user_grouping != groupBy
      $.ajax(
        url: Routes.user_path(users[0].id)
        dataType: 'json'
        type: 'PUT'
        data:
          user:
            settings: {work_order_group_by: groupBy}
      ).done(()->
        current_user_grouping = groupBy
      )

    selectedIndex = 0
    if groupBy is 'priority'
      selectedIndex = 0
      options = filtered_priorities
    else if groupBy is 'status'
      selectedIndex = 1
      options = filtered_statuses
    else if groupBy is 'wo_type'
      selectedIndex = 2
      options = filtered_wo_types
    else if groupBy is 'assigned_to'
      selectedIndex = 3
      options = _.findByValues(users, 'id', filtered_assigned_users)
    else if groupBy is 'created_by'
      selectedIndex = 4
      options = _.findByValues(users, 'id', filtered_opened_users)

    data = _.map(getWorkOrders(), (workOrder) -> $(workOrder).data("groups") )
    data = _.filter data, (el)->
      if statusFilter is 'closed'
        return el[1] is 'Closed'
      else
        return el[1] isnt 'Closed'
    data = _.map(data, (el)-> el[selectedIndex] )

    counts = _.countBy(data)

    previousActiveTabIndex = $('#group-options li.active').index()
    if selectedIndex <= 2
      innerHtml = _.map(options, (e, i) =>
        "<li><a data-toggle='tab' href='#'><span class='text'>#{e}</span> &nbsp;<span class='label-primary badge'>#{counts[e]}</span></a></li>"
      ).join("\n")
    else
      innerHtml = _.map(options, (e, i) =>
        "<li><a data-toggle='tab' href='#'><span class='text' data-id='#{e.id}'>#{e.name}</span> &nbsp;<span class='label-primary badge'>#{counts[e.id]}</span></a></li>"
      ).join("\n")
    $('ul#group-options').html(innerHtml)
    $('#wo-listing-spinner').hide()

    if data.length  > 0
      $('.work-orders').removeClass('hidden')
      $('.no-work-orders').text('').addClass('hidden')
    else
      $('.work-orders').addClass('hidden')
      $('.no-work-orders').removeClass('hidden')
      if searchString.length > 0
        $('.no-work-orders').text("There are no #{if statusFilter == 'active' then 'Open' else 'Closed'} work orders for search term '#{searchString}'")
      else
        $('.no-work-orders').text("There are no #{if statusFilter == 'active' then 'Open' else 'Closed'} work orders.")
      return

    # preserving selected tab index (if possible, if not - resetting it to 0)
    activeTabIndex =
    if previousActiveTabIndex isnt -1 && previousActiveTabIndex + 1 <= $('#group-options li').length
      previousActiveTabIndex
    else
      0
    active_tab = $( $('#group-options li').get(activeTabIndex) )
    if active_tab.length > 0
      active_tab.addClass('active').find('a').trigger('click')
    else
      workOrders.shuffle 'shuffle', ($el, shuffle)->
        false
  )

  $('#group-options').on('click', "a[data-toggle='tab']", ->
    if selectedIndex <= 2
      groupBy = $(this).find('.text').text()
    else
      groupBy = $(this).find('.text').data('id')
    workOrders.shuffle 'shuffle', ($el, shuffle)->
      if selectedIndex <= 2
        x = $.inArray(groupBy, $el.data('groups')) isnt -1
      else if selectedIndex == 3
        x = $el.data('groups')[3] == groupBy
      else if selectedIndex == 4
        x = $el.data('groups')[4] == groupBy
      statusMatched = if statusFilter is 'closed'
        $.inArray('Closed', $el.data('groups')) isnt -1
      else
        $.inArray('Closed', $el.data('groups')) is -1
      x && statusMatched && ($el.data('property-id').toString() == property_id) && searchFilter($el)
    opts =
      by: ($el) ->
        $el.data('priority')
    workOrders.shuffle 'sort', opts
  ).trigger('change')

  $("html")
    .on("fa.sidebar.minimize", -> workOrders.shuffle('enable'))
    .on("fa.sidebar.maximize", -> workOrders.shuffle('enable'))
  workOrders.shuffle('enable')

  $('body').on 'change', 'input.duration-type', (e) ->
    if @.checked
      $('.closing-confirmation-modal .duration-desc span.hours').addClass('text-primary')
      $('.closing-confirmation-modal .duration-desc span.minutes').removeClass('text-danger')
    else
      $('.closing-confirmation-modal .duration-desc span.minutes').addClass('text-danger')
      $('.closing-confirmation-modal .duration-desc span.hours').removeClass('text-primary')

  # editing WO:
  workOrders.on 'click', '.work-order', ->
    wo = $(@)
    wo.find('.indicator').show()
    $('#wo-modal').load Routes.edit_maintenance_work_order_path( $(@).data('wo-id'), {property_id: property_id} ), ->
      wo.find('.indicator').hide()
      $(@).find('select[name="maintenance_work_order[maintainable_type]"]').trigger 'change'
      $(@).modal()
      $(@).data('status', wo.data('groups')[1])
      $(@).find('input[name="maintenance_work_order[due_to_date]"]').datepicker(minDate: new Date())
      form = $(@).find('form.detail-form')
      applyPermissions(form)
      initializeMaterials($(@).find('.materials'))

      updateShuffle = (response) ->
        try workOrders.shuffle('remove', wo)
        updatedItem = $(response)
        workOrders.append(updatedItem).shuffle('appended', updatedItem)

      makeFormAjaxy(form, 'PUT', updateShuffle, wo)
      window.work_order_id = -1
      $(@).find('select[name="maintenance_work_order[status]"]').trigger('change')

  $('body').on 'ajax:success', '.delete-work-order', (e) ->
    $('.modal').modal('hide')
    workOrders.shuffle('remove', $(".work-order[data-wo-id=\"#{$(@).data('id')}\"]"))

  loadWorkOrders = () ->
    $('#wo-listing-spinner').show()
    data =
      format: 'js'
      filter:
        status: statusFilter
    if statusFilter == 'closed'
      data.filter.from = filterDateRange.from4rails()
      data.filter.to =  filterDateRange.to4rails()
      data.filter.wo_type = $('#wo_type').val() if !!$('#wo_type').val()
    $.ajax(
      url: Routes.maintenance_work_orders_path()
      type: 'GET'
      dataType: 'script'
      data: data
    ).complete(->
      getFilterOptions()
      $('.work-orders').css('overflow', 'hidden')
      if work_order_id
        wo = $('.work-order').filter("[data-wo-id='" + work_order_id + "']")
        $(wo).click()
    )

  arrayEqual = (a, b) ->
    a.length is b.length and a.every (e, i) -> e in b

  $('input[name=status-filter]').on 'change', ->
    statusFilter = $(@).val()
    $('.work-orders').removeClass('hidden')
    $('.no-work-orders').text('').addClass('hidden')
    if statusFilter == 'active' then $('#closed-filter').hide() else $('#closed-filter').show()
    loadWorkOrders()

  showDate = (start, end) ->
    $('#filter-date-range #range-value').html(start.format('MMM DD, YYYY') + ' - ' + end.format('MMM DD, YYYY'))
  showDate(moment().subtract(6, 'days'), moment())

  $('#filter-date-range').daterangepicker(
    ranges:
      'Today': [moment(), moment()],
      'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
      'Last 7 Days': [moment().subtract(6, 'days'), moment()],
      'Last 30 Days': [moment().subtract(29, 'days'), moment()],
      'This Month': [moment().startOf('month'), moment().endOf('month')],
      'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
    startDate: moment().subtract(6, 'days')
    autoApply: false
    linkedCalendars: false
  , showDate)

  $('#filter-date-range').on 'apply.daterangepicker', (e, picker) ->
    filterDateRange.from = picker.startDate
    filterDateRange.to = picker.endDate
    loadWorkOrders()

  $('#wo_type').on 'change', ->
    loadWorkOrders()

  $('#search').on 'input', $.debounce(250, ->
    searchString = $('#search').val().toLowerCase()
    getFilterOptions()
  )

  $('body').on 'change', '#wo-new-message #message-attachment', (e) ->
    file = e.target
    if file.files and file.files[0]
      $('#wo-new-message #attachment-name').val(file.files[0].name)
    else
      $('#wo-new-message #attachment-name').val('')

  message_template = $('.message-mustache-template').html()
  $('body').on 'click', '#wo-new-message .save-comment > a', (e) ->
    $messages = $('#wo-messages')
    model_id         = $messages.data('model-id')
    model_type       = $messages.data('model-type')
    user_avatar      = $messages.attr('data-user-avatar')
    user_name        = $messages.attr('data-user-name')

    $body = $('#wo-new-message #message-body')
    body = $body.val()
    if body.length == 0
      $body.addClass('parsley-error')
      $body.parent().find('ul.parsley-errors-list').remove()
      $body.after("<ul class='parsley-errors-list filled'><li class='parsley-required'>Comment body is required.</li></ul>")
      return false
    else
      $body.removeClass('parsley-error')
      $body.parent().find('ul.parsley-errors-list').remove()

    data = new FormData()
    files = $("#wo-new-message #message-attachment")[0].files
    attachment_exist = (files != undefined) && (files.length > 0)
    if attachment_exist
      data.append('attachment', files[0])
      $messages.find('.indicator').removeClass('hide')

    data.append('model_id', model_id)
    data.append('model_type', model_type)
    data.append('property_id', property_id)

    data.append 'body', body

    $.ajax(
      url: Routes.messages_path(),
      type: 'POST',
      data: data,
      cache: false,
      processData: false,
      contentType: false
    ).success((message, textStatus, jqXHR) ->
      addComment($messages, message)
      $messages.find('.media-list').data('message-count', $messages.find('.media-list').data('message-count') + 1)
      $('#wo-message-count').text($messages.find('.media-list').data('message-count'))
      $('#message-body, #message-attachment, #attachment-name').val('')
    ).error((jqXHR, textStatus, errorThrown) ->
    ).done(() ->
      $messages.find('.indicator').addClass('hide')
    )

  # Work Order Materials
  initializeMaterials = ($content) ->
    $form = $content.find('.new-material-form')
    $form.find('select.material-selector').selectize(
      plugins: ['no_results']
      valueField: 'id'
      labelField: 'name'
      searchField: 'name'
      placeholder: 'Enter 3 or more charaters...'
      render:
        item: (data) ->
          "<div data-value=\"#{data.id}\" data-price=\"#{data.purchase_price}\" data-unit=\"#{data.inventory_unit.name}\">#{data.name}</div>"
      load: (query, callback) ->
        return callback() if query.length < 3
        $.ajax(
          url: Routes.maintenance_materials_path(search: query)
          dataType: 'JSON'
        ).done( (res) ->
          callback(res)
        ).error( () ->
          callback()
        )
      onItemAdd: (value, $item) ->
        $form.find('.selectize-input').removeClass('has-error')
        $form.find('.price-control').removeClass('hidden')
        $form.find('.material-unit').text($item.data('unit'))
        $form.find('.material-price').text("$#{formatPrice($item.data('price'))}")
        $form.find('.material-quantity').data('price', $item.data('price'))
        $form.find('input#maintenance_material_price').val($item.data('price'))
        $('.material-item td').removeClass('selected')
        $(".material-item td[data-id=\"#{$item.data('value')}\"]").addClass('selected')
        validateAddMaterialButton()
      onChange: (value) ->
        validateAddMaterialButton()
    )
    $form.find('.material-quantity').numeric(decimalPlaces: 2)
    _.map($('table.material-list tr.material-item'), (record) ->
      $record = $(record)
      initializeEditable($record)
    )

  validateAddMaterialButton = () ->
    if !!$('select.material-selector').val() && !!$('.material-quantity').val()
      $('.add-material').removeClass('btn-default').addClass('btn-primary')
    else
      $('.add-material').removeClass('btn-primary').addClass('btn-default')

  initializeEditable = ($record) ->
    $record.find('.x-editable').on 'shown', (e, editable) ->
      if $(@).data('name') == 'quantity'
        editable.input.$input.numeric(decimalPlaces: 3)
      else if $(@).data('name') == 'price'
        editable.input.$input.numeric(decimalPlaces: 2)
    $record.find('.x-editable').editable
      params: (params)->
        data = {id: params.pk, maintenance_material: {}}
        data.maintenance_material[params.name] = params.value
        data
      validate: (val)->
        return 'This field is required' if parseFloat(val) == 0
      success: (response, newValue) ->
        cost = response.price * response.quantity
        $(@).parents('tr.material-item').attr('data-cost', cost)
        $(@).parents('tr.material-item').find('td.item-price').text("$#{formatPrice(cost)}")
        updateMaterialPrices()
      error: (errors) ->
        console.log(errors)

  addMaterialCallback = () ->
    $('.material-selector')[0].selectize.clear()
    $('.material-quantity').val('')
    $('.price-control').addClass('hidden')
    $('.material-quantity').data('price', null)
    $('.material-live-cost').addClass('hidden')
    $('.material-unit').text('')
    $('.material-item td').removeClass('selected')

  updateMaterialPrices = ()->
    $('.materials-total').removeClass('hidden')
    $('tr.no-materials').addClass('hidden')
    totalPrice = 0
    _.map($('table.material-list').find('tr.material-item'), (tr) ->
      totalPrice += parseFloat($(tr).attr('data-cost'))
    )
    $('.materials-total .value').html("$#{formatPrice(totalPrice)}")

  $('body').on 'ajax:error', '.new-material-form', (e, xhr, data, status) ->
    $.gritter.add(text: xhr.responseText, class_name: "alert alert-danger")

  $('body').on 'ajax:success', '.new-material-form', (e, xhr) ->
    $('table.material-list tbody').prepend(xhr)
    initializeEditable($('table.material-list tbody tr.material-item:first-child'))
    addMaterialCallback()
    updateMaterialPrices()

  $('body').on 'ajax:success', 'a.delete-material', (e, xhr) ->
    $(@).parents('tr.material-item').remove()
    updateMaterialPrices()
    if $('tr.material-item').length == 0
      $('.materials-total').addClass('hidden')
      $('tr.no-materials').removeClass('hidden')

  $('body').on 'ajax:error', 'a.delete-material', (e, xhr) ->
    $.gritter.add(text: xhr.responseText, class_name: "alert alert-danger")

  $('body').on 'ajax:complete', '.new-material-form', () ->
    $(@).find('button[type="submit"]').removeAttr('disabled')

  $('body').on 'input change', '.material-quantity', (e) ->
    if $(@).data('price')
      $('.material-live-cost').removeClass('hidden')
      cost = $(@).val() * $(@).data('price')
      $('.material-live-cost').text("$#{formatPrice(cost)}")
    validateAddMaterialButton()

  $('body').on 'submit', 'form.new-material-form', (e) ->
    if !$(@).find('select.material-selector').val()
      $(@).find('.selectize-input').addClass('has-error')
      return false
    $(@).find('button[type="submit"]').attr('disabled', 'disabled')