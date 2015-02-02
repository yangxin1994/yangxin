$ ->
  mark = null


  # soso.maps.event.addListener(map, "rightclick", (event) ->
  #   answer_id = window.answer_id
  #   $.ajax
  #     url: "/admin/answers/#{answer_id}/set_location"
  #     data: { lat: event.latLng.getLat(), lng: event.latLng.getLng()}
  #     method:"PUT"
  #     success: (ret)->
  #       if ret.success
  #         alert_msg.show('success', '成功设置访问点: [' + event.latLng.getLat() + ', ' + event.latLng.getLng() + ']')
  #         point = new soso.maps.LatLng(event.latLng.getLat(), event.latLng.getLng())
  #         marker.setVisible(false)
  #         marker = new soso.maps.Marker({position: point, map: map})
  #       else
  #         alert_msg.show('error', "操作失败-#{ret.value.error_code}-#{ret.value.error_code}")
  #     error: (ret)->
  #         alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")
  # )

  review = (is_pass, message_content, _this)->
    $this = $(_this)
    $.ajax
      url: "/admin/answers/#{$this.data("answer_id")}"
      method:"PUT"
      data:
        review_result: is_pass
        message_content: message_content
      success: (ret)->
        if ret.success
          $this.closest('span').html("")
          alert_msg.show('success', "操作完成!")
        else
          alert_msg.show('error', "操作失败-#{ret.value.error_code}-#{ret.value.error_code}")
      error: (ret)->
          alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")

  $("#btn_reject").click ->
    if remark = prompt("请输入拒绝理由", "答题不认真")
      alert_msg.show('info', "处理中, 请稍后...")
      $('html,body').animate({scrollTop: $('body').offset().top}, 300)
      review(false, remark, this)

   $("#btn_reject_whatever").click ->
    $this = $(this)
    if confirm("确定要拒绝该用户吗？")
      alert_msg.show('info', "处理中, 请稍后...")
      $('html,body').animate({scrollTop: $('body').offset().top}, 300)
      $.ajax
        url: "/admin/answers/#{$this.data("answer_id")}/reject"
        method:"PUT"
        success: (ret)->
          if ret.success
            $this.closest('span').html("")
            alert_msg.show('success', "操作完成!")
          else
            alert_msg.show('error', "操作失败-#{ret.value.error_code}-#{ret.value.error_code}")
        error: (ret)->
            alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")      
           
  $("#btn_pass").click ->
    unless $(this).hasClass('disabled')
      $(this).addClass('disabled')
      alert_msg.show('info', "处理中, 请稍后...")
      $('html,body').animate({scrollTop: $('body').offset().top}, 300)
      review(true, "", this)
