$ ->
  $('#btn_sub').click ->
    $this = $(this)
    $point = $('#p_point')
    _added = $('#point_amount').val()
    if (($point.html().toNumber() + _added.toNumber()) < 0)
      alert("用户至少要有0个积分!") 
      return false
    _id = $this.data("pid")
    $('#point_modal').modal('hide');

    alert_msg.show('info', "正在处理,请稍后...")
    $.ajax
      url: "/admin/samples/#{_id}/operate_point"
      method: 'PUT'
      data:
        sample_id: _id
        amount: $('#point_amount').val()
        markup: $('#point_markup').val()
      success: (ret)->
        if ret.success
          
          $point.html($point.html().toNumber() + _added.toNumber()) 
          $('tbody').prepend """
            <tr>
              <td>管理员操作</td>
              <td>#{Date.create().format('{hh}:{mm}')}</td>
              <td>
                #{_added}
              </td>
              <td>
                #{$('#point_markup').val()}
              </td>
            </tr>"""
          alert_msg.show('success', "操作完成!")
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")        
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")   
