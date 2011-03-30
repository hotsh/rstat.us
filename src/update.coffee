MAX_LENGTH = 140

$(document).ready ->
  $("html").removeClass("no-js").addClass("js")
  
  textarea = $("#update-form textarea")
  update_field = $("#update-form #update-referral")
  userTickiedBox = false

  updateCounter = ->
    remainingLength = MAX_LENGTH - textarea.val().length
    countSpan = $("#update-count .update-count").first()
    if countSpan.length
      countSpan.text(remainingLength)
    else
      $("#update-count").append('<span class="update-count">' + remainingLength + '</span>/' + MAX_LENGTH)
    $("#update-info").toggleClass "negative", remainingLength < 0

  textarea.keypress(updateCounter).keyup(updateCounter)

  updateTickyboxes = ->
    return if(userTickiedBox)

    firstLetter = ""
    if(textarea.val() != "")
      firstLetter = textarea.val()[0]

    enabled = true
    if firstLetter == "@"
      enabled = false

    if( $("#tweet").length > 0)
      $("#tweet").attr('checked', enabled)
    if( $("#facebook").length > 0)
      $("#facebook").attr('checked', enabled)
 
  textarea.keypress(updateTickyboxes).keyup(updateTickyboxes)

  recordTickyboxChange = ->
    userTickiedBox = true

  if( $("#tweet").length > 0)
    $("#tweet").change(recordTickyboxChange)
  if( $("#facebook").length > 0)
    $("#facebook").change(recordTickyboxChange)

  $("#update-form").submit ->
    false if textarea.val().length <= 0 || textarea.val().length > MAX_LENGTH
  
  shareText = (update) ->
    "RS @" + $(update).data("name") + ": " + $(update).find(".entry-content").text().trim()
    
  focusTextArea = (update) ->
    $(update_field).attr("value", $(update).data("id"))

    length = textarea.text().length
    textarea.keypress()
    textarea[0].setSelectionRange(length,length)
    textarea.focus()
    window.scrollTo(0, $(textarea).position().top)

  $(".has-update-form .update").each ->
    update = $(this)
    
    $(this).find(".reply").bind "click", (ev) ->
      ev.preventDefault()
      textarea.text("@" + $(update).data("name") + " ")
      focusTextArea(update)

    $(this).find(".share").bind "click", (ev) ->
      ev.preventDefault()
      textarea.text(shareText(update))
      focusTextArea(update)
      
  
