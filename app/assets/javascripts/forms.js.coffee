$(document).ready ->
  $('.selectize').selectize()

  submits = $('input.enabled-on-changes, button.enabled-on-changes')

  for submit in submits
    _submit = $(submit)
    _submit.prop('disabled', true)
    form = _submit.parents('form')
    initial_form = form.serialize()
    form.find(':input').on('change keyup keydown', ->
      if initial_form is form.serialize()
        _submit.prop('disabled', true)
      else
        _submit.prop('disabled', false)
    )


  $("input.numeric-input").numeric()
  $("input.currency-input").numeric(decimalPlaces: 2)
  $("input.currency-input, input.count-input, input.numeric-input").on 'click', (e)->
    $(@).select()
