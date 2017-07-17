$.fn.preventDoubleSubmission = () ->
  $(@).on 'submit', (e) ->
    $form = $(@)
    if $form.data('submitted') == true
      e.preventDefault()
    else
      $form.data('submitted', true)
  @