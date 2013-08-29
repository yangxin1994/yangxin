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