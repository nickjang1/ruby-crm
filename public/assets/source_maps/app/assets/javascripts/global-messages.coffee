class @GlobalMessages
  constructor: ->
    @dom = $(".global-messages")
    @dom.tooltip(
      html: true
      placement: "bottom"
      container: "body"
    )
    @messages = @dom.data("messages")
    @index = 0
    @updateStatus()
    @resize()

  addMessage: (message) ->
    position = _.findIndex(@messages, {id: message.id})
    if position == -1
      @messages.push message
      @updateStatus()
      @.resize() if @messages.length == 1

  removeMessage: (id) ->
    prevId = @currentId()
    position = _.findIndex(@messages, {id: id})
    if position != -1
      @messages.splice(position, 1)
      @updateStatus()
      if id == prevId
        @dom.text("").marquee("destroy")
        @.resize()

  updateStatus: ->
    $("#global-message-detail").text("(#{@index + 1} of #{@messages.length})")

  next: ->
    @index = (@index + 1) % @messages.length
    @.play()

  showToolTip: ->
    message = @messages[@index]
    messageText = """<div class="semibold">#{message.created_at_date}, #{message.created_at}<br>By: #{message.created_by}</div>""" + message.body
    @dom.attr("title", messageText).tooltip("fixTitle").tooltip("show")

  hideToolTip: ->
    @dom.tooltip("hide")
    @dom.attr("title", "").tooltip("fixTitle")

  currentId: ->
    message = @messages[@index]
    return "" unless message
    message.id

  currentText: ->
    message = @messages[@index]
    return "" unless message
    $("<div>#{message.body}</div>").text()

  currentBody: ->
    message = @messages[@index]
    return "" unless message
    message.body

  startMarquee: ->
    $this = @
    @updateStatus()
    @dom
      .bind("finished", ->
        $this.dom.marquee("destroy")
        $this.dom.html("""<div style="display: inline; white-space: nowrap;">#{$this.currentText()}</div>""")
        $this.nextTimeout = setTimeout(->
          $this.dom.html("")
          $this.next()
          $this.updateStatus()
        , 3000)
      )
      .marquee(
        duration: 3000
        delayBeforeStart: 5000
        direction: 'left'
        duplicated: false
        pauseOnHover: true
      )

  play: ->
    clearTimeout(@nextTimeout) if @nextTimeout
    if @messages.length > 0
      @dom.parents(".navbar-nav").css("display", "inline-block")
      window.updatePadding()
    else
      @dom.parents(".navbar-nav").css("display", "none")
      @dom.css("width", "1px")
      window.updatePadding()
      return
    @index = @index % @messages.length if @messages.length
    message = @messages[@index]
    return unless message
    @dom.text(@currentText())
    @.startMarquee()

  resize: ->
    @dom.css("width", "1px")
    window.updatePadding()
    if @messages.length > 0
      @dom.parents(".navbar-nav").css("display", "inline-block")
    else
      @dom.parents(".navbar-nav").css("display", "none")
      window.updatePadding()
      return
    offset = @dom.offset()
    rightOffset = $(".nav.navbar-nav.navbar-right").offset()
    width = rightOffset.left - offset.left - 5
    windowWidth = $(window).width()
    if windowWidth < 640 && width < 190
      width = windowWidth - offset.left - 5
    @dom.css("width", "#{width}px")
    @dom.marquee("destroy")
    @play()

GlobalMessagesDropdown = init: (options) ->
  coreDropdown = (e) ->
    $menu = $("#global-messages-menu")
    $header_menu = $(".global-messages-icon")
    if $header_menu
      right = $(window).width() - $header_menu.offset().left - $menu.width()
      right = 0 if right < 0
      $menu.css("right", right)
    $target = $(e.target)
    $mediaList = $target.find(".media-list")
    $indicator = $target.find(".indicator")

    $indicator.addClass("animation animating fadeInDown").one "webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", ->
      $(this).removeClass "animation animating fadeInDown"

    $mediaList.empty()
    template = $target.find("#global-messages-mustache-template").html()
    rendered = Mustache.render(template, messages: window.globalMessages.messages)
    $indicator.addClass "hide"
    $target.find(".count").html "(" + window.globalMessages.messages.length + ")"
    $mediaList.prepend rendered
    $mediaList.find(".media.new").each ->
      $(this).addClass("animation animating flipInX").one "webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", ->
        $(this).removeClass "animation animating flipInX"
  $(options.dropdown).on "shown.bs.dropdown", coreDropdown

$ ->
  window.globalMessages = new GlobalMessages()
  window.globalMessages.play()

  $("html")
    .on("fa.sidebar.minimize", -> window.globalMessages.resize())
    .on("fa.sidebar.maximize", -> window.globalMessages.resize())

  $(window).resize ->
    $menu = $("#global-messages-menu")
    $header_menu = $(".global-messages-icon")
    right = $(window).width() - $header_menu.offset().left - $menu.width()
    right = 0 if right < 0
    $menu.css("right", right)
    window.globalMessages.resize()

  GlobalMessagesDropdown.init
    dropdown: ".global-messages-icon"
