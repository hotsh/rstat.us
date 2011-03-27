(function() {
  var MAX_LENGTH;
  MAX_LENGTH = 140;
  $(document).ready(function() {
    var focusTextArea, shareText, textarea, updateCounter, update_field;
    $("html").removeClass("no-js").addClass("js");
    textarea = $("#update-form textarea");
    update_field = $("#update-form #update-referral");
    updateCounter = function() {
      var countSpan, remainingLength;
      remainingLength = MAX_LENGTH - textarea.val().length;
      countSpan = $("#update-count .update-count").first();
      if (countSpan.length) {
        countSpan.text(remainingLength);
      } else {
        $("#update-count").append('<span class="update-count">' + remainingLength + '</span>/' + MAX_LENGTH);
      }
      return $("#update-info").toggleClass("negative", remainingLength < 0);
    };
    textarea.keypress(updateCounter).keyup(updateCounter);
    $("#update-form").submit(function() {
      if (textarea.val().length <= 0 || textarea.val().length > MAX_LENGTH) {
        return false;
      }
    });
    shareText = function(update) {
      return "RS @" + $(update).data("name") + ": " + $(update).find(".text").text().trim();
    };
    focusTextArea = function(update) {
      var length;
      $(update_field).attr("value", $(update).data("id"));
      length = textarea.text().length;
      textarea.keypress();
      textarea[0].setSelectionRange(length, length);
      textarea.focus();
      return window.scrollTo(0, $(textarea).position().top);
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
