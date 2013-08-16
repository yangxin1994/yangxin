$ ->

  $(document).on 'click', '.od-stockin', (e)->
    e.preventDefault()
    $this = $(this)
    console.log $this
    $.ajax {
      type: 'PUT'
      url: "/admin/gifts/#{$(this).attr('href')}/stockup"
      success: (ret)->
        if ret.success
          $this.closest('td').prev().html("已上架")
          alert_msg.show('success', "礼品成功上架了!")
        else
          alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")

      error: ->
        alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")


    }

  $(document).on 'click', '.od-outstock', (e)->
    e.preventDefault()
    $this = $(this)
    console.log $this
    $.ajax
      type: 'PUT'
      url: "/admin/gifts/#{$(this).attr('href')}/outstock"
      success: (ret)->
        if ret.success
          $this.closest('td').prev().html("已下架")
          alert_msg.show('success', "礼品已经下架!")
        else
          alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")
      error: ->
        alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")

  $(document).on 'click', '.od-delete', (e)->
    e.preventDefault()
    $this = $(this)
    if confirm "确定要删除吗?"
      console.log e
      $.ajax
        type: 'DELETE'
        url: "/admin/gifts/#{$(this).attr('href')}"
        success: (ret)->
          if ret.success
            $this.closest('tr').fadeOut()
            alert_msg.show('success', "礼品已经删除!")
          else
            alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")
          error: ->
            alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")