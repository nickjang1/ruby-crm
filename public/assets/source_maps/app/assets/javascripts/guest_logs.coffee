$ ->
  return unless $('body').hasClass('guest-logs-page')

  currentDate = moment()
  loading = $('#loading')
  alarmWords = [
    'wake up'
    'wake-up'
    'wakeup'
  ]
  $('.summernote').summernote({
    height: 200,
    focus: true,
    toolbar: [
      ['style', ['style']],
      ['style', ['bold', 'italic', 'underline', 'clear']],
      ['fontsize', ['fontsize']],
      ['color', ['color']],
      ['para', ['ul', 'ol', 'paragraph']]
    ],
    onkeyup: (e) ->
      log = $('.summernote').code().toLowerCase()
      isAlarmMsg = _.filter(alarmWords, (e) -> log && log.indexOf(e) >= 0).length > 0
      if isAlarmMsg
        $('#btn-new-log').html("<i class='ico-alarm'/> <span class='hidden-xs'>Save Alarm</span>")
      else
        $('#btn-new-log').html("<i class='ico-checkmark'/> <span class='hidden-xs'>Save Comment</span>")

  })
  $('.note-editable').attr('data-placeholder', 'Type your comments here')

  $("#form-log").on "show.bs.collapse", ->
    $('#btn-new-log').html("<i class='ico-checkmark'/> <span class='hidden-xs'>Save Comment</span>")
    $('#btn-new-log').removeClass('btn-primary').addClass('btn-success')
    $('#btn-cancel').removeClass('hide')
    $('#btn-print').addClass('hide')
    $('.note-editable').trigger('focus');

    $('.summernote').code('')

  $("#form-log").on "hide.bs.collapse", (e) ->
    $('#btn-new-log').html("<i class='ico-plus-circle2'/> <span class='hidden-xs'>New Comment</span>")
    $('#btn-cancel').addClass('hide')
    $('#btn-print').removeClass('hide')
    $('#btn-new-log').removeClass('btn-success').addClass('btn-primary')

  # like guest log
  $('body').on 'click', '.panel-ribbon:not(.liked)', (e) ->
    $this = $(this)
    $.ajax(
      url: "/guest_logs/#{$this.data('id')}/like"
      type: 'GET'
      dataType: 'json'
    ).done (data)->
      rendered = Mustache.render($('.likes-mustache-template').html(), log: data)
      $this.parent().find('#likes').html(rendered)
      $this.addClass('liked')

  $('#btn-new-log').on 'click', (e) ->
    if $('#btn-new-log').hasClass('btn-success')
      log = $('.summernote').code()

      # if message starts with 'wakeup', process it as alarm
      if $(this).text() == ' Save Alarm'
        results = chrono.parse(log)
        if results.length > 0
          alarm =
            alarm_at: results[0].start.date()
            message: log

        $('#alarmConfirmationDialog #message').html(log.substr(0, results[0].index - 1))
        $('#alarmConfirmationDialog #alarm_at').text(moment(results[0].start.date()).format('MMM DD, HH:mm A'))
        $('#alarmConfirmationDialog #alarm_at').data('time', results[0].start.date())
        $('#alarmConfirmationDialog').modal()

        e.preventDefault()
        e.stopPropagation()
        return

      $.ajax(
        url: '/guest_logs'
        type: 'POST'
        dataType: 'json'
        data:
          body: log
      ).done (res) ->
        if isToday(currentDate)
          rendered = Mustache.render($('.guest-log-mustache-template').html(), log: res)
          $('.guest-logs').prepend(rendered)
          newElement = $('.guest-logs > .panel:first-child')
          newElement.addClass('animation animating bounceIn')
            .one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', ->
              $(this).removeClass('animation animating bounceIn')
            )

  # confirm action of alarm setting
  $('#alarmConfirmationDialog .confirm').on 'click', (e) ->
    $.ajax(
      url: '/guest_logs/set_alarm'
      type: 'POST'
      dataType: 'json'
      data:
        body: $('#alarmConfirmationDialog #message').html()
        alarm_at: $('#alarmConfirmationDialog #alarm_at').data('time')
    ).done (res) ->
      $('#form-log').collapse('hide')
      $.gritter.add(text: "New alarm was created for #{$('#alarmConfirmationDialog #alarm_at').text()}", class_name: 'alert alert-success')
      if isToday(moment($('#alarmConfirmationDialog #alarm_at').data('time')))
        getLogs(currentDate)

  # print guest logs
  $("#btn-print").on 'click', (e) ->
    url = "/guest_logs.pdf?date=#{currentDate.format('MM/DD/YYYY')}"
    window.open(url, '_blank')

  # check alarm
  $('.alarms').on 'click', '.check-alarm', (e) ->
    $alarmRow = $(this).parents('tr')
    alarmId = $alarmRow.data('id')
    $.ajax(
      url: "/guest_logs/#{alarmId}/check_alarm"
      type: 'GET'
      dataType: 'json'
    ).done (res) ->
      rendered = Mustache.render($('.alarm-mustache-template').html(), alarm: res)
      $alarmRow.replaceWith(rendered)

  # remove alarm
  $('.alarms').on 'click', '.remove-alarm', (e) ->
    showConfirmationDialog('Remove Alarm', $(@))

  $('body').on 'dialog:confirmed', '.remove-alarm', (e) ->
    $alarmRow = $(e.target).parents('tr')
    alarmId = $alarmRow.data('id')
    $.ajax(
      url: "/guest_logs/#{alarmId}/remove_alarm"
      type: 'DELETE'
      dataType: 'json'
    ).complete (res) ->
      $alarmRow.remove()
  # initailize datepicker
  $('.label-datepicker').datepicker
    maxDate: new Date()
    onSelect: (selectedDate) ->
      currentDate = moment(selectedDate)
      checkDateLabel()
      getLogs(currentDate)

  closeTimeout = null
  $('#input-query').on 'keydown', (e) ->
    if closeTimeout
      clearTimeout(closeTimeout)
    closeTimeout = setTimeout(filterLogs, 200)

  # search logs
  filterLogs = ->
    $query = $('#input-query').val().toLowerCase()
    if $query == ""
      $('.guest-logs .panel').removeClass('hide')
      return

    $.each $('.guest-logs .panel'), (i, obj) ->
      if $(obj).find('.log-body').text().toLowerCase().indexOf($query) >= 0
        $(obj).removeClass('hide')
      else
        $(obj).addClass('hide')

  # if user clicks the other area, collapse new log form
  $('#btn-cancel').on 'click', (e) ->
    $('#form-log').collapse('hide')

  # retrieve guest logs and alarms
  getLogs = (date) ->
    loading.show()
    $.ajax(
      url: '/guest_logs'
      type: 'GET'
      dataType: 'json'
      data:
        date: date.format()
    ).done (data)->
      $('.guest-logs').html('')
      $('.alarms table').html('')
      $.each(data.comments, (id, log) ->
        rendered = Mustache.render($('.guest-log-mustache-template').html(), log: log)
        $('.guest-logs').append(rendered)
      )
      if data.alarms.length > 0
        $.each(data.alarms, (id, alarm) ->
          rendered = Mustache.render($('.alarm-mustache-template').html(), alarm: alarm)
          $('.alarms table').append(rendered)
        )
        $('.alarms').removeClass('hide')
      else
        $('.alarms').addClass('hide')

    .complete -> loading.hide()

  $('#offset-minus').on 'click', ->
    currentDate.add(-1, 'd')
    getLogs(currentDate)
    checkDateLabel()

  $('#offset-plus').on 'click', ->
    currentDate.add(1, 'd')
    getLogs(currentDate)
    checkDateLabel()

  checkDateLabel = ->
    if isToday(currentDate)
      $('.label-datepicker').val('Today')
    else if isYesterday(currentDate)
      $('.label-datepicker').val('Yesterday')
    else
      $('.label-datepicker').val(currentDate.format('MM/DD/YYYY'))
    # Modify alarm logs date
    $('.selected-date').html($('.label-datepicker').val())

  isToday = (date) ->
    date.format('MMDDYYYY') == moment().format('MMDDYYYY')
  isYesterday = (date) ->
    date.format('MMDDYYYY') == moment().add(-1, 'd').format('MMDDYYYY')

  getLogs(currentDate)
  if window.location.hash.substr(1) == 'expanded'
    $('#form-log').collapse('show')
