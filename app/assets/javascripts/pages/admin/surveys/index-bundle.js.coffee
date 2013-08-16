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
          $('#info_modal').modal('show')
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
      success: (ret)->
        if ret.success
          alert_msg.show('success', "操作完成!")
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")        
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")       
