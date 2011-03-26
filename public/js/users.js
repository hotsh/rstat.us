(function() {
  $(document).ready(function() {
    return $(".unfollow").click(function() {
      return confirm("Are you sure you want to unfollow this this user?");
    });
  });
}).call(this);
