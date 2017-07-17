return unless $('body').hasClass('messaging-enabled-form')

MessagesDropdown = init: (options) ->
  coreDropdown = (e) ->
    $target = $(e.target)
    $mediaList = $target.find(".media-list")
    for msg in $mediaList.find('.message-item')
      $(msg).find('.message-created-at').html(moment($(msg).attr('data-created-at'), 'YYYY-MM-DD HH:mm:ssZ').fromNow())
    
  $(options.dropdown).on "shown.bs.dropdown", coreDropdown

$ ->
  MessagesDropdown.init
    dropdown: ".messages-dropdown"

  $('body').on 'change', '.new-message-modal #message-attachment', (e) ->
    file = e.target
    if file.files and file.files[0]
      $('.new-message-modal #attachment-name').val(file.files[0].name)
    else
      $('.new-message-modal #attachment-name').val('')
  
  $('.messages-dropdown #new-message, .add-message-btn').on 'click', (e) ->
    e.preventDefault()
    $messages        = $(this).parents('#model-messages, .page-header-section').find('.messages-dropdown')
    model_number     = $messages.attr('data-model-number') || ''
    model_id         = $messages.attr('data-model-id') || ''
    model_type       = $messages.attr('data-model-type')
    message_template = $('.message-mustache-template').html()
    user_avatar      = $messages.attr('data-user-avatar')
    user_name        = $messages.attr('data-user-name')
    bootbox.dialog
      title: "Add Comment to #{model_type.replace(/(Purchase|Maintenance::)/, '')} " + model_number,
      message: $('#new-message-form').html(),
      className: "new-message-modal",
      buttons:
        success: 
          label: "Save Comment",
          className: 'btn-primary',
          callback: ->
            $body = $('.new-message-modal #message-body')
            body = $body.val()
            if body.length == 0
              $body.addClass('parsley-error')
              $body.parent().find('ul.parsley-errors-list').remove()
              $body.after("<ul class='parsley-errors-list filled'><li class='parsley-required'>Comment body is required.</li></ul>")
              return false
            else
              $body.removeClass('parsley-error')
              $body.parent().find('ul.parsley-errors-list').remove()

            data = new FormData()
            files = $(".new-message-modal #message-attachment")[0].files
            attachment_exist = (files != undefined) && (files.length > 0)
            if attachment_exist
              data.append('attachment', files[0])
              $messages.find('.indicator').removeClass('hide')
            data.append('model_id', model_id)
            data.append('model_type', model_type)
            data.append 'body', body

            $.ajax(
              url: Routes.messages_path(), 
              type: 'POST', 
              data: data, 
              cache: false, 
              processData: false, 
              contentType: false
            ).success((message, textStatus, jqXHR) =>
              $resource = $(".messages-dropdown[data-model-id=#{model_id}]")
              $resource.find('span#messages-icon').addClass('text-primary')
              $resource.attr('data-message-ids', $messages.attr('data-message-ids') + ",#{message.id}")
              $resource.find('span#messages-alert-icon').removeClass('hidden')

              message.body = message.body.replace(/\n/g, "<br />")
              rendered = Mustache.render(
                message_template,
                message: message
              )
              $resource.find('.media-list').prepend rendered
              $resource.find('.media-list span.no-messages').remove()
              $resource.find('.media-list').data('message-count', $messages.find('.media-list').data('message-count') + 1)
              $resource.find('span.count').text("(#{$messages.find('.media-list').data('message-count')})")

              if message.attachment_exist
                $resource.find('.indicator').removeClass('hide')
                $resource.find('.media-list .message-item:first').attr('href', message.attachment_url)
            ).error((jqXHR, textStatus, errorThrown) ->

            ).done(() ->
              $messages.find('.indicator').addClass('hide')
            )
            
        danger:
          label: 'Cancel',
          className: 'btn-default'
          callback: ->
      , (result) ->
        console.log result
