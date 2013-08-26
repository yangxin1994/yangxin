$ ->
  $(document).on 'click', '.od-delete', (e)->
    e.preventDefault()
    self = $(this)
    console.log self
    if confirm "确定要删除吗?"
      console.log e
      $.ajax
        type: 'DELETE'
        url: "#{$(this).attr('href')}"
        success: ->
          self.parent().html("已删除")
          
