//= require jquery.zclip.js
//= require jQuery.blockUI
(($)->
  $.fn.clipboard = (opts) ->
    defaults = 
      text:''
    options = $.extend {},defaults,opts
    return @.each( ->
      succ = "<div class='succ_msg'><img src='/assets/share/success.png'></div>"
      $(@).zclip({
        path:'/assets/ZeroClipboard.swf',
        copy:options.text
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
)(jQuery)