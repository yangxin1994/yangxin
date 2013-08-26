$ ->
  $('#type_select a').click ->
    prize_type = parseInt($(this).attr('href').split('-')[1])
    $('#prize_type').val(prize_type)
    if $.inArray(prize_type, [4, 8, 16, 32]) == -1
      $("#amount_ctrl").hide()
    else
      $("#amount_ctrl").show()

  $('#amount_select a').click ->
    amount = $(this).attr('href').split('-')[1]
    $('#prize_amount').val(amount)

  $("#type_select a[href='#type-#{$('#prize_type').val()}']").click()

  $("#amount_select a[href='#amount-#{$('#amount').val()}']").click()

  $("#prize_form").validate
    rules:
      'prize[title]': 
          required: true      
      'prize[point]': 
          required: true
          digits: true
          min: 0
      'prize[price]': 
          required: true
          number: true
          min: 0          
      'prize[quantity]':
          required: true
          digits: true
          min: 0

    messages:
      'prize[title]': 
          required: "给奖品起一个名字吧"
      'prize[price]': 
          required: "还没有填写奖品价值呢"
          number: "价值请用表示数字"
          min: "价值不能低于0吧?"            
      'prize[point]': 
          required: "还没有填写所需积分呢"
          digits: "积分请用表示数字"
          min: "最少需要0个积分"
      'prize[quantity]':
          required: "奖品数量也是必须的"
          digits: "奖品数量是一个整数哦"
          min: "最少也得有0个奖品啊"