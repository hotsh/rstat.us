$(document).ready(function(){
  $("html").removeClass("no-js").addClass("js")
  var update = $("#update")

  function updateCounter(){
    $("#update-count").text((140 - update.val().length) + "/140");
    if(update.val().length > 140) {
      $("#update-info").addClass("negative");
    } else {
      $("#update-info").removeClass("negative");
    }
  };
  update.keypress(updateCounter).keyup(updateCounter)
  
  $("#update-form").submit(function() {
    if(update.val().length <= 0 || update.val().length > 140) {
      return false;
    }
    return true
  })
})
