$ ->
  $('#menu_button').click ->
    $('ul#little_menu_options').toggle()
    $(this).toggleClass('active')

  $('body').click (e) ->
    unless e.target.id == 'menu_button' || e.target.id == 'little_menu_options' || $(e.target).parents('ul').length > 0
      $('#menu_button').removeClass('active')
      $('ul#little_menu_options').hide()
