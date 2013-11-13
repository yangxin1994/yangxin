$ ->
  $(".delete").click ->
    $this = $(this)
    if confirm "确定要删除吗?"
      $.ajax
        url: "/admin/announcements/#{$this.data("aid")}"
        method: "DELETE"
        success: (ret)->
          if ret.success
            $this.closest('tr').fadeOut()
            alert_msg.show('success', "公告删除完成!")
          else
            alert_msg.show('error', "删除失败失败-#{ret.value.error_code}-#{ret.value.error_code}")
        error: (ret)->
            alert_msg.show('error', "删除失败失败 (╯‵□′)╯︵┻━┻")

  $(".star").click ->
    $this = $(this)
    icon = $this.find('i')
    $.ajax
      url: "/admin/announcements/#{$this.data("id")}/star"
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