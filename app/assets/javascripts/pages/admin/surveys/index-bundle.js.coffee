$ ->
  $(".dropselect a").click ->
    $this = $(this)
    $("#key_type").val($this.data('toggle'))

  $(".info").click ->
    $this = $(this).closest('td')
    $("#sid").val($this.data("sid"))
    $.ajax
      url: "/admin/surveys/#{$this.data("sid")}/more_info"
      method: "GET"
      success: (ret)->
        if ret.success
          $("#ck_hot").prop("checked", ret.value.hot)
          $("#point").val(ret.value.spread)
          $("#ck_visible").prop("checked", true) if ret.value.visible
          $("#max_num_per_ip").val(ret.value.max_num_per_ip)
          $('#info_modal').modal('show')
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")

  $(".cost").click ->
    $this = $(this).closest('td')
    $("#sid").val($this.data("sid"))
    reward_item = (item)->
      str = ''
      if item.rewards.length > 0
        for reward in item.rewards
          reward_type = ""
          if reward.type == 1
            reward_type = "虚拟"
          else if reward.type == 2
            reward_type = "实物"
          else if reward.type == 4
            reward_type = "话费"
          else if reward.type == 8
            reward_type = "支付宝"
          else if reward.type == 16
            reward_type = "集分宝"
          else if reward.type == 32
            reward_type = "Q币"
                    
          str += "<p>&nbsp;&nbsp;&nbsp;&nbsp;奖励类型 - #{reward_type}: #{reward.amount}</p>"
      str
    $.ajax
      url: "/admin/surveys/#{$this.data("sid")}/cost_info"
      method: "GET"
      success: (ret)->
        if ret.success
          $("#cost_body").html("<div id=\"cost_item\"></div>")
          for item in ret.value
            if item
              $("#cost_item").append("""
                <p>奖励方案 - #{item.name}:
                  <br>
                  #{reward_item(item)}
                </p>
                """)
          $('#cost_modal').modal('show')
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")    

  $("#send_info").click ->
    $('#info_modal').modal('hide');
    alert_msg.show('info', "正在处理,请稍后...")
    $.ajax
      url: "/admin/surveys/#{$("#sid").val()}/set_info"
      method: 'PUT'
      data:
        hot: $("#ck_hot").prop("checked")
        spread: $("#point").val()
        visible: $("#ck_visible").prop("checked")
        max_num_per_ip: $("#max_num_per_ip").val()
      success: (ret)->
        if ret.success
          alert_msg.show('success', "操作完成!")
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")        
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")

  $(".star").click ->
    $this = $(this)
    icon = $this.find('i')
    $.ajax
      url: "/admin/surveys/#{$this.data("id")}/star"
      method: 'PUT'
      data:
        star: icon.hasClass('icon-star')
      success: (ret)->
        if ret.success
          icon.attr('class', "icon-star#{if ret.value then "" else "-empty" }")
        else
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")        
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")

