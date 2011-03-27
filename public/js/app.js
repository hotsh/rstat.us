(function() {
  $(document).ready(function() {
    return $("#flash").delay(2000).slideUp('slow');
  });
}).call(this);

function focusOnDiv( divId )
{
divElement = document.getElementById( divId );
if(divElement!= null && typeof(divElement) != 'undefined')
{
divElement.focus();
}
}
