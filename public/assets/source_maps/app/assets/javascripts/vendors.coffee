vendorsPage = ->
  return unless $('body').hasClass('vendors-vpt-page')

  $('input[type="text"]').on('input', ->
    valid_inputs = $.grep($('input#vendor_division, input#vendor_department_number, input#vendor_customer_number'), ($input) ->
      $input.value.length  > 0 
    ).length
    $('input[name="vendor[vpt_enabled]"]').prop('checked', valid_inputs == 3)
  )
  
  
$(document).ready(vendorsPage)

