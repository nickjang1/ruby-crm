
$(document).on 'ready', ->

  $('body').on 'dialog.confirmed', '.send-fax-link', ->
    self = $(@)
    poId = self.data('id')
    if poId
      $.ajax
        url: Routes.send_fax_purchase_order_path(poId)
        dataType: 'json'
        method: "POST"
        success: (data)->
          alertMessage = data['message']
          $.gritter.add
            time: 5000
            text: alertMessage
            class_name: "alert alert-success"
        error: (xhr) ->
          alertMessage = $.parseJSON(xhr.responseText).message
          $.gritter.add
            time: 5000
            text: alertMessage
            class_name: "alert alert-danger"
