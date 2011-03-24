(function() {
  $(document).ready(function() {
    var update, updateCounter;
    $("html").removeClass("no-js").addClass("js");
    update = $("#update-textarea");
    updateCounter = function() {
      $("#update-count").text((140 - update.val().length) + "/140");
      return $("#update-info").toggleClass("negative", update.val().length > 140);
    };
    update.keypress(updateCounter).keyup(updateCounter);
    return $("#update-form").submit(function() {
      if (update.val().length <= 0 || update.val().length > 140) {
        return false;
      }
    });
  });
}).call(this);
