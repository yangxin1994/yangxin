$ ->
  $('#type_select a').click ->
    $('#gift_type').val($(this).attr('href').split('-')[1])

  $('#redeem_select a').click ->
    redeem_mode = $(this).attr('href').split('-')[1]
    $('#gift_redeem').val(redeem_mode)
    if redeem_mode is '1'
      $('#redeem_ary').hide()
      $('#redeem_range').hide()
    else if redeem_mode is '2'
      $('#redeem_ary').hide()
      $('#redeem_range').show()
    else if redeem_mode is '4'
      $('#redeem_ary').show()
      $('#redeem_range').hide()

  $("#type_select a[href='#type-#{$('#gift_type').val()}']").click()

  $("#redeem_select a[href='#redeem-#{$('#gift_redeem').val()}']").click()

  $("#gift_form").validate
    rules:
      'gift[title]': 
          required: true      
      'gift[point]': 
          required: true
          digits: true
          min: 0
      'gift[quantity]':
          required: true
          digits: true
          min: 0

    messages:
      'gift[title]': 
          required: "给礼品起一个名字吧"      
      'gift[point]': 
          required: "还没有填写所需积分呢"
          digits: "积分请用表示数字"
          min: "最少需要0个积分"
      'gift[quantity]':
          required: "礼品数量也是必须的"
          digits: "礼品数量是一个整数哦"
          min: "最少也得有0个礼品啊"