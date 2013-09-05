$ ->

  $("#attr_select a[href='#type-#{$('#attribute_type').val()}']").click()

  $(document).on 'click', '.delete-btn', (e)->
    e.preventDefault()
    $this = $(this)
    _id = $(this).attr('href').split('-')[1]
    if confirm "确定要删除吗?"
      console.log e
      $.ajax
        type: 'DELETE'
        url: "/admin/samples/#{_id}/destroy_attributes"
        success: (ret)->
          if ret.success
            $this.closest('tr').fadeOut()
            alert_msg.show('success', "已经删除!")
          else
            alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")
          error: ->
            alert_msg.show('error', "删除失败 (╯‵□′)╯︵┻━┻")

  $('.attr-ipt').hide()

  $('#attr_select a').click ->
    $this = $(this)
    attribute_type = parseInt($(this).attr('href').split('-')[1])
    $('#attribute_type').val(attribute_type)
    _href = $this.attr("href")
    $this.parent().parent().next('input').val(_href.split('-')[1])
    _class = _href.split('#')[1]
    $('.attr-ipt').hide()
    $this.closest(".control-group").next(".control-group").find(".#{_class}").fadeIn()

  $('.datef-select a').click ->
    $this = $(this)
    _href = $this.attr("href")
    $this.parent().parent().next('input').val(_href.split('-')[1])

  $('#eattr_select a').click ->
    $this = $(this)
    _val = $this.attr("href").split('-')[1]
    $this.parent().parent().next('input').val(_val)
    switch parseInt(_val) 
      when 0
        $('.enum').fadeOut()
      when 1
        $('.enum').fadeIn()
      when 2
        $('.enum').fadeOut()
      when 3
        $('.enum').fadeOut()
      when 6
        $('.enum').fadeOut()

  # ##################################################
  
  $('.date-type-input').each ->
    $this = $(this)
    $this.prev("ul").find("a[href='#datef-#{$this.val()}']").click()
  
  $("#eattr_select a[href='#eattr-#{$("#eattr_ipt").val()}']").click()

  $("#attr_select a[href='#attr-#{$('#attribute_type').val()}']").click()

