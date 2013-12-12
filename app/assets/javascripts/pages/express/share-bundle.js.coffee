//=require ui/plugins/od_float_link
//=require ui/plugins/od_social_share
//=require ui/plugins/od_clipboard

$ ->

  $('.socials').share(title:$('.social_channel .title').text(),url:$('input[name="link"]').val())

  $('.left_part').SurveyLink(href:$('input[name="link"]').val())

  $('.sub_nav li').bind('click',(e) ->
    tab_class = $(@).attr('class')
    $('.share_info').find('.' + tab_class).show().siblings().hide()
    unless $(@).hasClass('last')  
      $(@).addClass('active').siblings().removeClass('active')     
  )

  $('.copy_button').clipboard(text:$('input[name="link"]').val())

  $('li.site_net').click(->
    $('.code_button').clipboard(text:$('.pre_code').text())
  )

  $('.s_bottom img').hover(
    ->
      $('.overlay').show()
    ->
      $('.overlay').hide()

  )

  $('.overlay').click(->
    url = window.location.href.replace('share','')
    $.getJSON(url + "down_qrcode.json", (data)->)
  )

  $('.add_psw a').click(->
    $(@).hide().siblings('input').show().select()
  )

  $('.password').focusout(->
    psw = $.trim($(@).val().toLowerCase())  
    $.putJSON("/e/questionaires/#{window.survey_id}/update_access_pass",{single_password:psw},(data)->
      $('.password').hide().prev('a').text('修改密码成功').show()
    )
  )




  
  