$(document).ready ->
  $("#flash").delay(2000).slideUp('slow')

function focusOnDiv(divId)
  divElement: document.getElementById(divId)
  if divElement != null and typeofdivElement != "undefined"
    divElement.focus()


