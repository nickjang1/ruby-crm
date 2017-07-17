window.isTouchDevice = ->
  $('html').hasClass('touch')

window.updatePropertyTimeZone = (zone) ->
  $("#property-time").attr("data-timezone", zone)

window.getPropertyTimeZone = ->
  $("#property-time").attr("data-timezone")

$(document).ready ->
  updateTime = ->
    $("#property-time").text(moment().tz(window.getPropertyTimeZone()).format("hh:mm A"))

  setInterval(updateTime, 1000)