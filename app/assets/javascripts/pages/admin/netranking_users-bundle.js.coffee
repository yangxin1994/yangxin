$ ->
  $(document).on 'click', '.od-delete', (e)->
    $this = $(this)
    $.ajax
      type: 'DELETE'
      url: "/admin/netranking_users/#{$(this).data('id')}"
      success: (ret)->
        if ret.success
          $this.closest('tr').fadeOut()
          alert_msg.show('success', "已经删除!")
        else
          alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")
      error: ->
        alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")
          
  $(document).on 'click', '.add-email', (e)->
    $this = $(this)
    $.ajax
      type: 'POST'
      url: "/admin/netranking_users"
      success: (ret)->
        if ret.success
          $this.closest('tr').fadeOut()
          alert_msg.show('success', "已经删除!")
        else
          alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")
      error: ->
        alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")
          
