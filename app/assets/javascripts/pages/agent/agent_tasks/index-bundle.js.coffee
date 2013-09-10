$ ->
  $('.survey-url').click ->
    prompt "答题地址", $(this).data('url')

  $.ajaxSetup
    headers: 
      'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')

  $('.st-open').click ->
    $this = $(this).closest("td")
    $.ajax
      data: {}
      url: "/agent/tasks/#{$this.data('id')}/open"
      method: "PUT"
      success: (ret)->
        if ret.success
          $this.closest('span').html("")
          alert_msg.show('success', "操作完成!")
        else
          alert_msg.show('error', "操作失败-#{ret.value.error_code}-#{ret.value.error_code}")
      error: (ret)->
          alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")

  $('.st-close').click ->
    $this = $(this).closest("td")
    $.ajax
      data: {}
      url: "/agent/tasks/#{$this.data('id')}/close"
      method: "PUT"
      success: (ret)->
        if ret.success
          $this.closest('span').html("")
          alert_msg.show('success', "操作完成!")
        else
          alert_msg.show('error', "操作失败-#{ret.value.error_code}-#{ret.value.error_code}")
      error: (ret)->
          alert_msg.show('error', "操作失败 (╯‵□′)╯︵┻━┻")      
