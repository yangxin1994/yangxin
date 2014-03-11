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
          alert_msg.show('error', "处理失败,请稍后重试")
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试")

  $(".promote").click ->
    $this = $(this).closest('td')
    $("#sid").val($this.data("sid"))
    $('#promote_modal').modal('show')
    $.ajax
      url: "/admin/surveys/#{$this.data("sid")}/promote_info"
      method: "GET"
      success: (ret)->
        console.log ret
        if ret.success
          $("#email_sended").html(ret.value.email.promote_email_count)
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试")
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试")  

  $(".cost").click ->
    $this = $(this).closest('td')
    $("#sid").val($this.data("sid"))
    $.ajax
      url: "/admin/surveys/#{$this.data("sid")}/cost_info"
      method: "GET"
      success: (ret)->
        if ret.success
          for k, v of ret.value
            $('#' + k).text(v)
          $('#cost_modal').modal('show')
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试")
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试")    

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
          alert_msg.show('error', "处理失败,请稍后重试")        
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试")

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
          alert_msg.show('error', "处理失败,请稍后重试")        
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试")

  $(".batch-reject").click ->
    $this = $(this)
    sid = $this.data("sid")
    stitle = $this.data("stitle").truncate(10)
    $("#answer_list_vld").html("")
    $("#survey_title").html(stitle)
    $("#breject_form").attr("action", "/admin/answers/#{sid}/batch_reject")
    $('#batch_modal').modal('show')

  $("#breject_btn").click ->
    if $("#answer_list").val()
      $('#batch_modal').modal('hide')
      alert_msg.show('success', "请等待处理，处理结果会会自动下载。")
    else
      $("#answer_list_vld").html("* 请选择csv文件！")
      return false
    


