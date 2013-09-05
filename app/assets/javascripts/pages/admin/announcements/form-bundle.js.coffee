//= require "jquery.qeditor"

$ ->
  $("#content_body").qeditor({});

  $('.dropdown-menu a').click ->
    $this = $(this)
    info = $this.attr('href').split('-')
    $this.parent().parent().next().val(info[1])