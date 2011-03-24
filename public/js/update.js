(function() {
  $(document).ready(function() {
    var focusTextArea, shareText, textarea, updateCounter, update_field;
    $("html").removeClass("no-js").addClass("js");
    textarea = $("#update-form textarea");
    update_field = $("#update-form #update-referral");
    updateCounter = function() {
      $("#update-count").text((140 - textarea.val().length) + "/140");
      return $("#update-info").toggleClass("negative", textarea.val().length > 140);
    };
    textarea.keypress(updateCounter).keyup(updateCounter);
    $("#update-form").submit(function() {
      if (textarea.val().length <= 0 || textarea.val().length > 140) {
        return false;
      }
    });
    shareText = function(update) {
      return "RT @" + $(update).data("name") + ": " + $(update).find(".text").text().trim();
    };
    focusTextArea = function(update) {
      var length;
      $(update_field).attr("value", $(update).data("id"));
      length = textarea.text().length;
      textarea.keypress();
      textarea[0].setSelectionRange(length, length);
      return textarea.focus();
    };
    return $(".update").each(function() {
      var update;
      update = $(this);
      $(this).find(".reply").bind("click", function(ev) {
        ev.preventDefault();
        textarea.text("@" + $(update).data("name") + " ");
        return focusTextArea(update);
      });
      return $(this).find(".share").bind("click", function(ev) {
        ev.preventDefault();
        textarea.text(shareText(update));
        return focusTextArea(update);
      });
    });
  });
}).call(this);
