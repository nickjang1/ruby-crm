buildConfirmationDialogHTML = (message, position = 'top')->
  """
    <div id="confirmationDialog" class="modal #{position}" tabindex="-1" role="dialog" aria-hidden="true">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <a class="close" data-dismiss="modal">×</a>
            <h4>#{message}</h4>
          </div>
          <div class="modal-body">
            <p>Are you sure you want to do this?</p>
          </div>
          <div class="modal-footer">
            <button class="btn modal-close" aria-hidden="true">NO!</button>
            <a data-dismiss="modal" class="btn btn-danger confirm">YES I'm sure!</a>
          </div>
        </div>
      </div>
    </div>
  """

@showConfirmationDialog = (message, element) ->
  modal = $ buildConfirmationDialogHTML(message)
  modal.modal()
  modal.prev().css("z-index": "1050")
  modal.find('.confirm').on 'click', -> (element || $('body')).trigger('dialog:confirmed')
  modal.find('.modal-close').on 'click', ->
    $('#confirmationDialog').prev().remove()
    $('#confirmationDialog').remove()
    (element || $('body')).trigger('dialog:cancelled')
  modal

$.rails.allowAction = (link) ->
  return true unless link.attr('data-confirm')
  $.rails.showConfirmDialog(link) # look bellow for implementations
  false # always stops the action since code runs asynchronously

$.rails.confirmed = (link) ->
  link.removeAttr('data-confirm') unless link.attr('data-ajax')
  link.trigger('click.rails')
  $('#confirmationDialog, .modal-backdrop').remove()

$.rails.showConfirmDialog = (link) ->
  message = link.attr 'data-confirm'
  position = link.attr 'data-position'
  html = buildConfirmationDialogHTML(message, position)

  $(html).modal()
  $('#confirmationDialog .modal-footer .modal-close').on 'click', ->
    $('#confirmationDialog, .modal-backdrop').remove()
    $(this).off 'click'

  $('#confirmationDialog .confirm').on 'click', ->
    # link.data('dialog-confirmed', false)
    $.rails.confirmed(link)
    link.trigger('dialog.confirmed')
    $(this).off 'click'
