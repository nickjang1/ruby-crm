$ ->
  # create next cycle link click handler (when there are ant existing expired cycles)
  $('body').on 'click', '.create-new-cycle', ->
    $.gritter.removeAll
      after_close: ->
        $.ajax(Routes.create_next_maintenance_cycles_path(format: 'json'), type: 'POST').done (data)->
          messages = "<ul>" + $(data).map(-> "<li>#{@.cycle_type} Cycle ##{@.cycle_number} for #{@.year} has started</li>" ).toArray().join("") + "</ul>"
          $.gritter.add
            text: messages
            class_name: "alert alert-success"

  $('body').on 'click touchstart', '.wo-image .add-image', (e) ->
    e.stopPropagation()
    $(this).parent().find('.img-file').trigger('click')

  $('body').on 'click', '.wo-image:not(.empty) .img-file', ->
    window.open($(this).attr('src'), '_blank');

  $('body').on 'click touchstart', '.wo-image.empty .img-file', (e) ->
    e.stopPropagation()
    $(@).next().find("input[type='file']").trigger('click')

  # Click event of image delete button
  $('body').on 'click', '.wo-image button.btn-danger', ->
    $(this).parent().parent().find("input[type='file']").val('')
    $(this).parent().parent().find('.img-file').attr('src', '/assets/default_image.png')
    $(this).parents('.wo-image').addClass('empty')

  $("body").on 'change', "input.comment-attachment", (input) ->
    evt = input.target
    if evt.files and evt.files[0]
      reader = new FileReader

      reader.onload = (e) ->
        $(evt).parent().prev().attr 'src', e.target.result
        $(evt).closest('.wo-image').removeClass('empty')
        return

      reader.readAsDataURL evt.files[0]
