//=require ui/plugins/od_float_link
//= require jquery.zclip.js
//= require jQuery.blockUI

$ ->
  $('.left_part').SurveyLink(href:'http://sina.com')

  $('.sub_nav li').bind('click',(e) ->
    tab_class = $(@).attr('class')
    $('.share_info').find('.' + tab_class).show().siblings().hide()
    unless $(@).hasClass('last')  
      $(@).addClass('active').siblings().removeClass('active')     
  )

  $('li.site_net').click(->
    succ = "<div class='succ_msg'><img src='/assets/share/success.png'></div>"
    $('.code_button').zclip({
      path:'/assets/ZeroClipboard.swf',
      copy:$('.pre_code').text(),
      afterCopy:->
        $.blockUI({ 
          message: succ, 
          fadeIn: 700, 
          fadeOut: 700, 
          timeout: 2000, 
          showOverlay: false, 
          centerY: false, 
          css: { 
            width: '350px', 
            height:'70px',
            'line-height':'100px',
            border: 'none', 
            padding: '5px', 
            backgroundColor: '#000', 
            '-webkit-border-radius': '10px', 
            '-moz-border-radius': '10px', 
            opacity: .6, 
            color: '#fff' 
          } 
        })
    })
  )

  
  