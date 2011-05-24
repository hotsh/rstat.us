(function() {
  var MAX_LENGTH;
  MAX_LENGTH = 140;
  $(document).ready(function() {
    var focusTextArea, recordTickyboxChange, shareText, textarea, updateCounter, updateTickyboxes, update_field, userTickiedBox;
    $("html").removeClass("no-js").addClass("js");
    $("#flash").delay(2000).slideUp('slow');
    $("#pitch").equalHeights();
    textarea = $("#update-form textarea");
    update_field = $("#update-form #update-referral");
    userTickiedBox = false;
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
      return "RS @" + $(update).data("name") + ": " + $(update).find(".entry-content").text().trim();
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
    $(".has-update-form .update").each(function() {
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
    $(".remove-update").click(function() {
      return confirm("Are you sure you want to delete this update?");
    });
    updateTickyboxes = function() {
      var enabled, firstLetter;
      if (userTickiedBox) {
        return;
      }
      firstLetter = "";
      if (textarea.val() !== "") {
        firstLetter = textarea.val()[0];
      }
      enabled = true;
      if (firstLetter === "@") {
        enabled = false;
      }
      if ($("#tweet").length > 0) {
        $("#tweet").attr('checked', enabled);
      }
      if ($("#facebook").length > 0) {
        return $("#facebook").attr('checked', enabled);
      }
    };
    textarea.keypress(updateTickyboxes).keyup(updateTickyboxes);
    recordTickyboxChange = function() {
      return userTickiedBox = true;
    };
    if ($("#tweet").length > 0) {
      $("#tweet").change(recordTickyboxChange);
    }
    if ($("#facebook").length > 0) {
      $("#facebook").change(recordTickyboxChange);
    }
    return $(".unfollow").click(function() {
      return confirm("Are you sure you want to unfollow this user?");
    });
  });
}).call(this);
