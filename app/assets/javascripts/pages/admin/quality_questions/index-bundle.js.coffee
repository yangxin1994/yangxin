$ ->
  $(document).on 'click', '.od-delete', (e)->
    $this = $(this)
    if confirm "确定要删除吗?"
      $.ajax
        type: 'DELETE'
        url: "/admin/quality_questions/#{$this.data('id')}"
        success: (ret)->
          if ret.success
            $this.closest('tr').fadeOut()
            alert_msg.show('success', "问题已经删除!")
          else
            alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")
        error: ->
          alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")