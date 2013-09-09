$ ->
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
          digits: true
          min: 0          
      'prize[quantity]':
          required: true
          digits: true
          min: 0

    messages:
      'prize[title]': 
          required: "给奖品起一个名字吧"
      'prize[price]': 
          required: "还没有填写所需积分呢"
          digits: "积分请用表示数字"
          min: "价值不能低于0吧?"            
      'prize[point]': 
          required: "还没有填写所需积分呢"
          digits: "积分请用表示数字"
          min: "最少需要0个积分"
      'prize[quantity]':
          required: "奖品数量也是必须的"
          digits: "奖品数量是一个整数哦"
          min: "最少也得有0个奖品啊"