(function() {
  $(document).ready(function() {
    return $(".remove-update").click(function() {
      var r;
      r = confirm("Are you sure you want to delete this update?");
      return r;
    });
  });
}).call(this);
