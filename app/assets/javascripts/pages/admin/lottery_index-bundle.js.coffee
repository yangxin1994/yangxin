$(->
  ####### 抽奖流程控制 ######
  $(".button-update").click ->
    prize_id = $(this).parent().parent().attr("id")
    $.ajax {
      type: 'PUT',
      url: "/admin/lotteries/" + $(".table-prizes").attr("id") + "/add_ctrl_rule",
      data: {
        ctrl_time: $('#ctrl_time' + prize_id).val(),
        ctrl_surplus: $('#ctrl_surplus' + prize_id).val(),
        ctrl_prize: prize_id,
        weight: $('#weight' + prize_id).val()
      }
      success: (retval) ->
        if retval.success
          alert("更新成功！")
        else if retval.value == "error_21207"
          alert("更新失败:(\n请输入正确的数据格式")
        else
          alert("更新失败:(\n" + "错误代码：" + retval.value)          
    }
    return false

  ####### 抽奖首页 ######

  $('.ck_status').click ->
    lid = $(this).attr('id').replace /ck_(public|display)_/, ''
    console.log lid
    status = 0
    if $("#ck_public_#{lid}").attr('checked')
      status += 2
    if $("#ck_display_#{lid}").attr('checked')
      status += 1
    console.log status
    $.ajax {
      type: 'PUT',
      url: "/admin/lotteries/#{lid}/status",
      data: {
        status: status
      }
    }

  $('#btn-lottery_delete').click ->
    lid = $(this).attr('href')
    r = confirm('确定删除吗')
    console.log r
    if r == true
      $.ajax {
        type: 'DELETE',
        url: "/admin/lotteries/#{lid}"
        success: ->
          alert('删除成功')
          window.location.href = '/admin/lotteries'
        errro: ->
          alert('出现错误')
      }
    return false

  $('#btn-auto_draw').click ->
    lid = $(this).attr('href')
    r = confirm('确定抽奖吗')
    console.log r
    if r == true
      $.ajax {
        type: 'GET',
        url: "/admin/lotteries/#{lid}/auto_draw"
        success: ->
          window.location.href = "/admin/lotteries/#{lid}/reward_records"
        errro: ->
          alert('出现错误')
      }
    return false

  # 奖品分配
  $('.btn-assign').click ->
    uid = $(this).attr('href')
    lid = window.lottery._id
    pid = $("##{uid} .ctrl_prize").val()
    r = confirm('确定分配吗')
    console.log pid
    if r == true
      $.ajax {
        type: 'PUT'
        url: "/admin/lotteries/#{lid}/assign_prize_to"
        data: {
          user_id : uid,
          prize_id : pid
        }
        success: ->
          window.location.href = window.location.href
        errro: ->
          alert('出现错误')
      }
    return false
  #恢复被删除lottery
  $('.btn-revive_lottery').live 'click', ->
    lid = $(this).attr('href')
    $.ajax {
      type: 'PUT'
      url: "/admin/lotteries/#{lid}/revive"
      success: (ret)->
        # console.log ret
        window.location.href = "/admin/lotteries/#{lid}"
      errro: ->
        alert '出现错误'
    }
    false
  # 用户搜索
  $('#btn-search_user').click ->
    stype = $("#select-user").val()
    lid = window.lottery._id
    if $("#text-keyword").val()
      window.location.href = "/admin/lotteries/#{lid}/assign_prize?#{stype}=#{$("#text-keyword").val()}"
    else
      alert "请填写关键字"
      return false
    return false
  $(document).keyup (e) ->
    if e.which == 13
      $('#btn-search_user').click()

  # 显示prize详情
  $('#show_prize').hide()
  $('.prize_name').click ->
    # $('#show_prize').html "adfsafdsfasdfdasfsad"
    pid = $(this).attr 'href'
    $.ajax {
      type: 'GET'
      url: "/admin/prizes/#{pid}.html"
      success: (ret)->
        $('#show_prize').html(ret)
      errro: ->
        alert '出现错误'
    }
    $('#show_prize').lightbox_me({
      centered: true
      onClose: ->$('#show_prize').html('<img src="/assets/images/loaders/loader8.gif"/>')
      });
    false

  return true
)
