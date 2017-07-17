Notifications = init: (options) ->
  coreDropdown = (e) ->
    $menu = $("#notification-menu")
    $header_menu = $("#header-notifications")
    if $header_menu
      right = $(window).width() - $header_menu.offset().left - $menu.width()
      right = 0 if right < 0
      $menu.css("right", right)
    $target = $(e.target)
    $mediaList = $target.find(".media-list")
    $indicator = $target.find(".indicator")
    
    $indicator.addClass("animation animating fadeInDown").one "webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", ->
      $(this).removeClass "animation animating fadeInDown"

    $.ajax(
      url: options.url
      cache: false
      type: "GET"
      dataType: "json"
    ).done (notifications) ->
      $mediaList.empty()
      template = $target.find("#notification-mustache-template").html()
      rendered = Mustache.render(template, notifications: notifications)
      $indicator.addClass "hide"
      $target.find(".count").html "(" + notifications.length + ")"
      $mediaList.prepend rendered
      $mediaList.find(".media.new").each ->
        $(this).addClass("animation animating flipInX").one "webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", ->
          $(this).removeClass "animation animating flipInX"
  $(options.dropdown).on "shown.bs.dropdown", coreDropdown

getNotificationIds = ->
  $('#header-notifications a.notification-item').map ->
    $(@).data('id')
  .get()

removeAlert = ->
  $('#header-notifications #notification-icon-image').removeClass 'text-danger'
  has_notification = false
  $.each $('#header-notifications a.notification-item'), (e) ->
    has_notification = true unless $(e).hasClass('read')
  $('#header-notifications #notification-icon-image').addClass('text-danger') if has_notification

$ ->
  Notifications.init
    dropdown: "#header-notifications"
    url: Routes.notifications_path(unread: true)

#  $("#header-notifications").on 'click', 'a.notification-item', (e) ->
#    e.preventDefault()
#    item = $(@)
#    item_id = item.data('id')
#    link_url = item.data('link')
#    link_method = item.data('method')
#    $.ajax(
#      url: Routes.notification_path(item_id)
#      cache: false
#      type: "PUT"
#      dataType: "json"
#    ).always (data) ->
#      item.addClass('read')
#      form = $('<form action="' + link_url + '" method="' + link_method + '">' + '</form>')
#      $("body").append(form)
#      form.submit()
#      removeAlert()

  $("#header-notifications .clear-notifications").on 'click', (e) ->
    e.preventDefault()
    ids = getNotificationIds()
    $.ajax(
      url: Routes.notification_path(0, ids: ids)
      cache: false
      type: "DELETE"
      dataType: "json"
    ).always (data) ->
      $("#header-notifications .media-list").empty()
      $("#header-notifications span.count").text("(0)")
      removeAlert()

  $(window).on 'resize', (e) -> 
    $menu = $("#notification-menu")
    $header_menu = $("#header-notifications")
    right = $(window).width() - $header_menu.offset().left - $menu.width()
    right = 0 if right < 0
    $menu.css("right", right)
