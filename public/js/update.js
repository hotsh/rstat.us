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

// TODO: MOVE TO COFFEE-SCRIPT FOO
function reply(username) {
  update = $("#update-textarea");
  update.text("@" + username + " ");
  update.focus();
}

function share(username, update_id) {
  update = $("#update-textarea");
  update_text = $("#update-" + update_id).text().trim();
  update.text("RT @" + username + ": " + update_text);
  update.focus();
}
