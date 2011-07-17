(function() {
  $(document).ready(function() {
    return $(".unfollow").click(function() {
      return confirm("Are you sure you want to unfollow this user?");
    });
  });
}).call(this);
