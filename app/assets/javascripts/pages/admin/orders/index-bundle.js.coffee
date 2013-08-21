$ ->
  if querilayer.queries.type
    $('ul.flowy-admin-sidenav a').each ->
      $this = $(this)
      _type = $this.attr('href').split('=')[1]
      $this.closest('li').addClass('active') if _type == querilayer.queries.type
  else
     $('ul.flowy-admin-sidenav a:first').closest('li').addClass('active')

  $('table').popover
    selector: '.o-detail'
    container: 'tr'

  $(".handle").click ->
    $this = $(this)
    order_id = $this.attr('href').split('-')[1]

    $.ajax
      url: "/admin/orders/#{order_id}/handle"
      type: 'PUT'
      success: (ret)->
        if ret.success
          $this.addClass 'disabled'
          $this.html("已开始处理")
          $this.unbind('click')
          alert_msg.show('success', "操作完成!")
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")
      error: (ret)->
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")

  $(".finishs").click ->
    $this = $(this)
    order_id = $this.attr('href').split('-')[1]
    $.ajax
      url: "/admin/orders/#{order_id}/finish"
      type: 'PUT'
      data:
        success: true
      success: (ret)->
        if ret.success
          $this.addClass('disabled').html("已完成处理").unbind('click')
          $this.closest('.btn-group').find('.finishf').remove()
          alert_msg.show('success', "操作完成!")
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")
      error: (ret)->
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")


  $(".finishf").click ->
    $this = $(this)
    order_id = $this.attr('href').split('-')[1]

    if remark = prompt("拒绝原因","管理员拒绝")
      $.ajax
        url: "/admin/orders/#{order_id}/finish"
        type: 'PUT'
        data:
          success: false
          remark: remark
        success: (ret)->
          if ret.success
            $this.closest('.btn-group').find('.finishs').addClass('disabled').html("已完成处理").unbind('click')
            $this.remove()
            alert_msg.show('success', "操作完成!")
          else
            console.log ret
            alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")
        error: (ret)->
            alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")

  $(document).on "click", ".remark", ->
    $this = $(this)
    order_id = $this.attr('href').split('-')[1]
    $("#orid").val($this.attr('href').split('-')[1])
    $("#ipt_remark").val $this.data('remark')
    $('#remark_modal').modal('show')


  $("#send_remark").click ->
    $('#remark_modal').modal('hide');
    alert_msg.show('info', "正在处理,请稍后...")
    orid = $("#orid").val()
    _remark = $("#ipt_remark").val()
    $.ajax
      url: "/admin/orders/#{orid}/update_remark"
      type: 'PUT'
      data: remark: _remark
      success: (ret)->
        if ret.success
          $("#remark_#{orid}").data("remark", _remark)
          alert_msg.show('success', "操作完成!")
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")
      error: (ret)->
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")

  $(".express").click ->
    $this = $(this)
    if $this.data("express")
      _express = JSON.parse($this.data("express")) 
      $("#company").val(_express.company)
      $("#tracking_number").val(_express.tracking_number)
      $("#sent_at").val(_express.sent_at)

    $("#oid").val($this.attr('href').split('-')[1])
    $('#info_modal').modal('show')

  $("#send_info").click ->
    $('#info_modal').modal('hide');
    alert_msg.show('info', "正在处理,请稍后...")
    _ep: 
      company: $("#company").val()
      tracking_number: $("#tracking_number").val()
      sent_at: $("#sent_at").val()
    $.ajax
      url: "/admin/orders/#{$("#oid").val()}/update_express_info"
      method: 'PUT'
      data:
        express_info:_ep
      success: (ret)->
        if ret.success
          alert_msg.show('success', "操作完成!")
        else
          console.log ret
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")        
      error: ->
          alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ")

  $ ->
    alert_msg.show('info', "点击订单行区域可查看详细")

