$(document).ready ->
  $('body').on 'dialog.confirmed', '.vpt-send-order', ->
    self = $(@)
    poId = self.data('id')
    if poId
      $.ajax(
        url: Routes.send_vpt_purchase_order_path(poId)
        dataType: 'json'
        method: "POST"
      ).done((data)->
        window.open data.url, '_blank'
      ).fail((xhr) ->
        alertMessage = $.parseJSON(xhr.responseText).error
        $.gritter.add
          time: 5000
          text: "Order Sending Failed<br>Reason: #{alertMessage}"
          class_name: "alert alert-danger"
      )
