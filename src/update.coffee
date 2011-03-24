$(document).ready ->
  $("html").removeClass("no-js").addClass("js")
  update = $("#update-textarea")

  updateCounter = ->
    $("#update-count").text((140 - update.val().length) + "/140")
    $("#update-info").toggleClass "negative", update.val().length > 140

  update.keypress(updateCounter).keyup(updateCounter)

  $("#update-form").submit ->
    false if update.val().length <= 0 || update.val().length > 140
