return unless $('body').hasClass('property-setting')

$(document).ready ->
  $content = $('#permission-content')
  role_id = $content.data('role-id')
  department_id = $content.data('department-id')
  filter = $content.data('filter')

  load_permissions = ->
    $('#loading-indicator').addClass('show')
    $content.load Routes.permissions_path(role_id: role_id, department_id: department_id, filter: filter), ->
      $('#save-permissions').attr('disabled', 'true')
      $('body').find('input[name="permissions[maintenance_work_order][index][all]"]').trigger('change')
      $('#loading-indicator').removeClass('show')
      $('#departments').selectize()

  $('body').on 'shown.bs.tab', '#role-list a[data-toggle="tab"]', ->
    role_id = $(@).data('id')
    load_permissions()

  $('body').on 'change', '#permissions_department', () ->
    department_id = $(@).val()
    load_permissions()

  $('body').on 'change', 'input[type=checkbox]', (e) ->
    $this = $(@)
    $next = $this.parents('.expandable').next()
    if $next.hasClass('detail-items')
      $next.toggleClass('hidden')
    $('#save-permissions').removeAttr('disabled')

  $('body').on 'change', 'input[name="permissions[maintenance_work_order][index][all]"]', (e) ->
    checked = $(@).is(':checked')
    $('input[name="permissions[maintenance_work_order][index][department]"]').attr('disabled', checked)
    if $('#departments').length > 0
      department_selectize = $("#departments").selectize()[0].selectize
      if checked
        department_selectize.clear()
        department_selectize.disable()
      else
        department_selectize.enable()
        department_selectize.addItems($('#permissions_department').val()) if department_selectize.items.length == 0

  $('#permissions-filter > button').on 'click', ->
    filter = $(@).data('value')
    $('#permissions-filter > button').removeClass('btn-success').addClass('btn-default')
    $(@).removeClass('btn-default').addClass('btn-success')
    load_permissions()

  load_permissions()

  $("#property-setting-form").on "ajax:success", (e, data, status, xhr) ->
    console.log data
    window.updatePropertyTimeZone(data.time_zone)
    $.gritter.add
      text: "Proprety setting has been updated."
      class_name: "alert alert-success"
  .on "ajax:error", (e) ->
    $.gritter.add
      text: "Failed to update property setting."
      class_name: "alert alert-danger"
