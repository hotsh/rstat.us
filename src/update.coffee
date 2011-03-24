$(document).ready ->
  $("html").removeClass("no-js").addClass("js")
  
  textarea = $("#update-form textarea")
  update_field = $("#update-form #update-referral")

  updateCounter = ->
    $("#update-count").text((140 - textarea.val().length) + "/140")
    $("#update-info").toggleClass "negative", textarea.val().length > 140

  textarea.keypress(updateCounter).keyup(updateCounter)

  $("#update-form").submit ->
    false if textarea.val().length <= 0 || textarea.val().length > 140
  
  shareText = (update) ->
    "RT @" + $(update).data("name") + ": " + $(update).find(".text").text().trim();
    
  focusTextArea = ->
    textarea.keypress()
    textarea.focus()
  
  $(".update").each ->
    update = $(this)
    
    $(this).find(".reply").bind "click", (ev) ->
      ev.preventDefault();
      textarea.text("@" + $(update).data("name") + " ")
      focusTextArea()

    $(this).find(".share").bind "click", (ev) ->
      ev.preventDefault();
      textarea.text(shareText(update))
      focusTextArea()
      
  