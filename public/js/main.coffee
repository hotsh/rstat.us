MAX_LENGTH = 140

$(document).ready ->
  
  # Turn on JS styles
  $("html").removeClass("no-js").addClass("js")

  # Hide flash messages
  $("#flash").delay(2000).slideUp('slow')
  
  #########################################
  # Homepage
  #########################################
  
  # Set equal heights for 3-column area
  $("#pitch").equalHeights()
  
  #########################################
  # Update Form
  #########################################
  textarea = $("#update-form textarea")
  update_field = $("#update-form #update-referral")
  userTickiedBox = false

  # Manage update character count
  updateCounter = ->
    remainingLength = MAX_LENGTH - textarea.val().length
    countSpan = $("#update-count .update-count").first()
    if countSpan.length
      countSpan.text(remainingLength)
    else
      $("#update-count").append('<span class="update-count">' + remainingLength + '</span>/' + MAX_LENGTH)
    $("#update-info").toggleClass "negative", remainingLength < 0

  textarea.keypress(updateCounter).keyup(updateCounter)

  # Validate form on submit
  $("#update-form").submit ->
    false if textarea.val().length <= 0 || textarea.val().length > MAX_LENGTH
  
  # Helper method for RS messages
  shareText = (update) ->
    "RS @" + $(update).data("name") + ": " + $(update).find(".entry-content").text().trim()
    
  # Helper method to add text and move cursor to correct position
  focusTextArea = (update) ->
    $(update_field).attr("value", $(update).data("id"))

    length = textarea.text().length
    textarea.keypress()
    textarea[0].setSelectionRange(length,length)
    textarea.focus()
    window.scrollTo(0, $(textarea).position().top)

  # If update form, target when clicking reply and insert appropriate text
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
  
  # Delete update check
  $(".remove-update").click ->
    confirm "Are you sure you want to delete this update?"
  
  # Manage reply state and service share checkboxes
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
  
  #########################################
  # Users
  #########################################
  $(".unfollow").click ->
    confirm "Are you sure you want to unfollow this user?"

  