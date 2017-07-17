getCheckedIds = ->
  $('#shuffle-grid input:checkbox:checked').map ->
    $(@).val()
  .get()

$(document).on 'ready page:load', ->
  $('#order_selected').on 'click', ->
    tag_ids = getCheckedIds()
    if tag_ids.length
      window.location.href = Routes.new_purchase_request_path q: {tags_id_eq_any: tag_ids}
    else
      alert "You must select #{$(@).attr('data-controller')}"

  $('.panel-checkbox input[type="checkbox"]').on 'change', (e) ->
    current_id = $(e.target).val()
    tag_ids = getCheckedIds()
    order_btns = tag_ids.map (i) ->
      "#tag-order-#{i}"
    .join(', ')

    # action bar order selected button
    if tag_ids.length > 0
      $("#order_selected").attr('disabled', false)
    else
      $("#order_selected").attr('disabled', true)

    # tag order buttons
    if tag_ids.length > 1
      $(order_btns).attr('disabled', true)
    else
      $(order_btns).attr('disabled', false)

    if $.inArray(current_id, tag_ids) == -1
      $("#tag-order-#{current_id}").attr('disabled', false)
    else if tag_ids.length > 1
      $("#tag-order-#{current_id}").attr('disabled', true)
    else
      $("#tag-order-#{current_id}").attr('disabled', false)

$(document).on 'click', '#tag-form .add_btn', (event) ->
  $(@).removeClass 'add_btn'
  $(@).addClass 'remove_btn'
  $(@).removeClass 'btn-success'
  $(@).addClass 'btn-danger'

  i = $(@).find('i')
  i.removeClass 'ico-plus-circle2'
  i.addClass 'ico-trash'

  $('.enabled-on-changes').removeAttr('disabled')

  row = $(@).closest('tr')
  row.removeClass 'danger'
  row.addClass 'success'
  row.find('input[type=checkbox]').prop 'checked', true

  excluded_table = $('#excluded table').dataTable()
  aPos = excluded_table.fnGetPosition(row.get(0))
  excluded_table.fnDeleteRow(aPos)
  $('#included table').dataTable().fnAddData(row)

$(document).on 'click', '#tag-form .remove_btn', (event) ->
  $(@).removeClass 'remove_btn'
  $(@).addClass 'add_btn'
  $(@).removeClass 'btn-danger'
  $(@).addClass 'btn-success'

  i = $(@).find('i')
  i.removeClass 'ico-trash'
  i.addClass 'ico-plus-circle2'

  $('.enabled-on-changes').removeAttr('disabled')

  row = $(@).closest('tr')
  row.removeClass 'success'
  row.addClass 'danger'
  row.find('input[type=checkbox]').prop 'checked', false
  included_table = $('#included table').dataTable()
  aPos = included_table.fnGetPosition(row.get(0))
  included_table.fnDeleteRow(aPos)
  $('#excluded table').dataTable().fnAddData(row)
