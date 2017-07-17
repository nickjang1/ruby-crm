departmentsFormPage = ->
  return unless $('body').hasClass('departments-form')

  $(document).on 'click', '.add_btn', (event) ->
    $('.enabled-on-changes').removeAttr('disabled')
    row = $(@).closest('tr')
    row.addClass 'success'
    row.find('input[type=checkbox]').prop 'checked', true
    false

  $(document).on 'click', '.remove_btn', (event) ->
    $('.enabled-on-changes').removeAttr('disabled')
    row = $(@).closest('tr')
    row.removeClass 'success'
    row.find('input[type=checkbox]').prop 'checked', false
    false


$(document).ready departmentsFormPage