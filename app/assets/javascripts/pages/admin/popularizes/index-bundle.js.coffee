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

  $("tbody").sortable({ axis: "y" })


  $("tbody").sortable({
    axis: "y",
    stop:->
      id_arr = $.map($('tbody tr'),(colum)->
        return $(colum).attr('id')
      )
      $.putJSON('/admin/popularizes/sort.json',{ids:id_arr},->
      )
      
    
  })



)