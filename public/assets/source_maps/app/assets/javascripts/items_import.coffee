itemsImportPage = ->
  return unless $('body').hasClass('items-import')

  $("form#import-form #template-file").on 'change', (e) ->
    file = e.target
    if file.files and file.files[0]
      $("form#import-form #template-filename").val(file.files[0].name)
      $("form#import-form #import-button").prop 'disabled', false
    else
      $("form#import-form #template-filename").val('')

  $("form#import-form #import-button").on 'click', (e) ->
    e.preventDefault()
    $("#importing-spinner").removeClass('hidden').addClass('show')
    setTimeout (->
      $("form#import-form").submit()
    ), 500

$(document).ready(itemsImportPage)
