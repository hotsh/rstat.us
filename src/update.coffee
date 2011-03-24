$(document).ready ->
  $("html").removeClass("no-js").addClass("js")
  update = $("#update-textarea")

  updateCounter = ->
    $("#update-count").text((140 - update.val().length) + "/140")
    if update.val().length > 140
      $("#update-info").addClass("negative")
    else
      $("#update-info").removeClass("negative")

  update.keypress(updateCounter).keyup(updateCounter)

  $("#update-form").submit ->
    if update.val().length <= 0 || update.val().length > 140
      false
    else
      true
