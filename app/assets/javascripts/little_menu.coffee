$ ->
  $('#menu_button').click ->
    $('ul#little_menu_options').toggle()
    $(this).toggleClass('active')

  $('body').click (e) ->
    console.log e.target.id
    unless e.target.id is 'menu_button' or 'little_menu_options'
      $('#menu_button').removeClass('active')
      $('ul#little_menu_options').hide()
