$(document).ready ->
  alertClasses = {
    info: 'info'
    alert: 'danger'
    warning: 'warning'
    error: 'danger'
    notice: 'success'
  }

  showMessages = (messages, gritterParams, additionalClass="")->
    $.each messages, (i, message)->
      alertClass = alertClasses[message[0]]

      $.gritter.add $.extend gritterParams,
        text: message[1]
        class_name: "alert alert-#{alertClass} #{additionalClass}"

  showMessages( $('.alert-messages').data('messages'), {time: 5000} )
  showMessages( $('.alert-messages').data('messages-sticky'), {sticky: true}, 'alert-message-no-close-bth' )
