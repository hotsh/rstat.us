(function() {
  $(document).ready(function() {
    return $(".remove-update").click(function() {
      return confirm("Are you sure you want to delete this update?");
    });
  });
}).call(this);
