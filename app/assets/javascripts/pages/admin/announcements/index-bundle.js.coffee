$ ->
	$(".delete").click ->
		$this = $(this)
		$.ajax
			url: "/admin/announcements/#{$this.data("aid")}"
			method: "DELETE"
			success: (ret)->
        if ret.success
          $this.closest('tr').remove()
          alert_msg.show('success', "公告已经完成!")
        else
          alert_msg.show('error', "删除失败失败-#{ret.value.error_code}-#{ret.value.error_code}")
      error: (ret)->
          alert_msg.show('error', "删除失败失败 (╯‵□′)╯︵┻━┻")