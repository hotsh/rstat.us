$(document).ready(function(){
  var update = $("#update")

  function updateCounter(){
    $("#update_count").text((140 - update.val().length) + "/140");
    if(update.val().length > 140) {
      $("#update-info").addClass("negative");
    } else {
      $("#update-info").removeClass("negative");
    }
  };

  update.keypress(updateCounter).keyup(updateCounter)
  
  $("#update_button").click(function() {
    $("#update-form").submit();
  })
  
  $("#update-form").submit(function() {
    if(update.val().length <= 0 || update.val().length > 140) {
      return false;
    }
    return true
  })
})
