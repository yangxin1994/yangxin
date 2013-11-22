//= require jquery
//= require sugar-1.3.9.min
//= require twitter/bootstrap/button
//= require twitter/bootstrap/tab
//= require twitter/bootstrap/modal
//= require twitter/bootstrap/alert
//= require twitter/bootstrap/tooltip
//= require twitter/bootstrap/dropdown
//= require twitter/bootstrap/popover
//= require utility_admin/querilayer
//= require utility_admin/checklist
//= require jquery.validate.min
//= require jquery.validate.bootstrap.popover

class Alert
  initialize: ->

  show: (type, msg)->
    $('#alert_placeholder').html(
      "
      <div class=\"alert alert-#{type}\">
        <button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button>
        #{msg}
      </div>
      "
    )
    alert_div = $('.alert')
    setTimeout ->
        alert_div.fadeOut
          complete: -> alert_div.remove()
      ,5000

  hide: ->
    $('.alert').remove()

$ ->
  $(document).on 'click', 'ul.dropselect a', ->
    $this = $(this)
    $this.parent().parent().prev('button.btn:not(a)').html(" #{$this.html()} <span class=\"caret\"></span>")

  do ->
    if querilayer.queries.keyword
      $search_input = $('input.search-query')
      $search_input.val(querilayer.queries.keyword)
      $search_input.removeClass('span6')
      $search_input.addClass('span10')
    
  $('input.search-query').focusin ->
    $this = $(this)
    $this.removeClass('span6')
    $this.addClass('span10')

  $('input.search-query').focusout ->
    $this = $(this)
    console.log $this.val()
    unless $this.val()
      $this.removeClass('span10')
      $this.addClass('span6')

  window.alert_msg = new Alert
