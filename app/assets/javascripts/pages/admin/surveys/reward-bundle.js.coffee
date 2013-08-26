$ ->

  $prize_group = $('#prize_group')
  $point_group = $('#point_group')
  $cash_group = $('#cash_group')    

  # ===============
  
  $(document).on 'click', '.dropdown-menu a', ->
    $this = $(this)
    info = $this.attr('href').split('-')
    # $("#{info[0]}_amount").val(info[1])
    $this.parent().parent().next().val(info[1])

  $(document).on 'click', '.prize a', ->
    $this = $(this)
    info = $this.attr('href').split('-')
    $this.parent().parent().next().val(info[1])

  $(document).tooltip
    placement: 'bottom'
    title: '年份可以省略,只写月日:MM/DD'
    selector: '.reward-time'

  $('#cash_btn').click ->
    $('#prize_group').hide()
    $('#point_group').hide()
    $('#cash_group').fadeIn()
    $('#ipt_free').val('no')

  $('#point_btn').click ->
    $('#prize_group').hide()
    $('#point_group').fadeIn()
    $('#cash_group').hide()
    $('#ipt_free').val('no')

  $('#prize_btn').click ->
    $('#prize_group').fadeIn()
    $('#point_group').hide()
    $('#cash_group').hide()
    $('#ipt_free').val('no')

  $('#free_btn').click ->
    $('#prize_group').hide()
    $('#point_group').hide()
    $('#cash_group').hide()
    $('#ipt_free').val('yes')

  $('#add_prize').click ->
    $this = $(this)
    index = $this.data('toggle') + 1

    add_html = "<div class=\"control-group\">
      <div class=\"controls\">
        <div class=\"input-prepend\">
          <div class=\"btn-group\">
            <button class=\"btn dropdown-toggle\" data-toggle=\"dropdown\">
              选择奖品
              <span class=\"caret\"></span>
            </button>
            <ul class=\"dropdown-menu dropselect prize\">
              #{$('.dropselect.prize:first').html()}
            </ul>
            <input type=\"hidden\" class=\"prize-id\" name=\"reward_scheme[prizes][#{index}][id]\">
          </div>
          <input name=\"reward_scheme[prizes][#{index}][prob]\" class=\"input-mini\" type=\"text\"  placeholder=\"中奖率\" >
          <input name=\"reward_scheme[prizes][#{index}][amount]\" class=\"input-mini\" type=\"text\" placeholder=\"个数\" >
          <input name=\"reward_scheme[prizes][#{index}][deadline]\" class=\"input-small reward-time\" type=\"text\" placeholder=\"YY/MM/DD\" >
        </div>
      </div>
    </div>"   
    $this.data('toggle', index)
    # console.log $this.parent()
    # console.log $this.parent().parent()
    $this.parent().parent().parent().prepend(add_html)

  do ->
    $prize_group.hide()
    $point_group.hide()
    $cash_group.hide()
    $("##{_rval}_btn").click() if _rval = $("#reward_type").val()

  $(".dropselect.prize li a").each ->
    $this = $(this)
    if $this.attr("href") == "#prize-#{$this.parent().parent().next().val()}"
      $this.click()

  # $("#amount_select a[href='#amount-#{$('#amount').val()}']").click()

  # $('#delete_btn').click ->
  #   $this = $(this)
  #   $.ajax
  #     url: "/admin/reward_schemes/#{querilayer.queries.editing}"
  #     method: 'delete'
  #     data:
  #       survey_id: $this.attr('href').split('-')[1]
  #     success: ->

  #     error: ->