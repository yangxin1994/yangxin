//=require 'utility/ajax'
//=require 'jquery.ui.1.10.3'

$(->
  $('input.upload').on('change',->
    img_url = $(@).val()
    $('.ipt-holder').text(img_url) 
  )

  $('form button').on('click',->
    img_url = $('input.upload').val()
    if img_url.length < 1
      return false  
  )

  $('a.delete').click(->
    tr = $(@).parent().parent()
    banner_id = $(@).attr('data')
    $.deleteJSON("/admin/popularizes/#{banner_id}"  ,{},(retval)->
      if retval.success
        tr.remove()
    )
  )

  $("tbody.pop").sortable({
    axis: "y",
    stop:->
      id_arr = $.map($('tbody tr'),(colum)->
        return $(colum).attr('id')
      )
      $.putJSON('/admin/popularizes/sort.json',{ids:id_arr},->
      )
  })

  $('.add-reward button').click(->
    $(@).addClass('disabled').text('正在操作...').attr('disabled',true)
    ids = []
    $.each($('tbody tr'),(idx,tr)->
      ids.push($(tr).attr('id'))
    )
    id_arr = $.unique(ids)
    $.postJSON('/admin/popularizes/add_reward',{user_ids: id_arr},(retval)->
      if retval.success
        unless retval.value.length > 0 
          window.location.href = "/admin/popularizes/weibo?success=true"
        else
          return $.error("id为列表中的用户奖励没有成功:" + retval.value) 
          
    )


  )



)