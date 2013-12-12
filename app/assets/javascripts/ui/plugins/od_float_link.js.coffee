//= require jquery.ui.slider
(($)->
  $.fn.SurveyLink = (options) ->
    defaults = 
      selected:'#s_A'
      href: ''
      top:250

    opts = $.extend {},defaults,options

    return @.each( ->
      $this    = $(@)
      top      = opts.top
      style    = "style='position:fixed;right:0px;top:#{top}px;'"
      img_src  = window.location.origin + '/assets/share/' + $(opts.selected).attr('id') + '.png'
      pre_code = "<div id='float_link' #{style}><a href='#{opts.href}' target='_blank'><img src='#{img_src}' /></a></div>"
      $('.pre_code').text(pre_code)
      $('.float_link').css({'top':opts.top})
      $('.float_link img').attr('src',img_src)

      $(@).find('input[type="radio"]').click( (e)->
        e.stopPropagation
        $(@).parent('label').addClass('active').siblings().removeClass('active')
        style    = "style='position:fixed;right:0px;top:#{opts.top}px;'"
        img_src  = window.location.origin + '/assets/share/' + $(@).attr('id') + '.png'
        pre_code = "<div id='float_link' #{style}><a href='#{opts.href}' target='_blank'><img src='#{img_src}' /></a></div>"
        $('.pre_code').text(pre_code)
        $('.float_link').css({'top':opts.top})
        $('.float_link img').attr('src',img_src)
      )

      $( ".scale_c" ).slider({
        range: "min",
        value: 250,
        min: 0,
        max: 500,
        slide: ( event, ui ) -> 
          $( ".val" ).text('高度' + ui.value + 'px' )
          top      = ui.value
          opts.top = top
          style    = "style='position:fixed;right:0px;top:#{opts.top}px'"
          img_src  = window.location.origin + '/assets/share/' + $("label.active" ).children('input').attr('id') + '.png'
          pre_code = "<div id='float_link' #{style}><a href='#{opts.href}' target='_blank'><img src='#{img_src}' /></a></div>"
          $('.pre_code').text(pre_code)
          $('.float_link').css({'top':opts.top})
          $('.float_link img').attr('src',img_src)
      })

      $('.val').text( "高度" + $( ".scale_c" ).slider( "value" ) + 'px' ); 

      # succ = "<div class='succ_msg'><img src='/assets/share/success.png'></div>"
      # $('.code_button').zclip({
      #   path:'/assets/ZeroClipboard.swf',
      #   copy:$('.pre_code').text(),
      #   afterCopy:->
      #     console.log('ddd')
      #     $.blockUI({ 
      #       message: succ, 
      #       fadeIn: 700, 
      #       fadeOut: 700, 
      #       timeout: 2000, 
      #       showOverlay: false, 
      #       centerY: false, 
      #       css: { 
      #         width: '350px', 
      #         height:'70px',
      #         'line-height':'100px',
      #         border: 'none', 
      #         padding: '5px', 
      #         backgroundColor: '#000', 
      #         '-webkit-border-radius': '10px', 
      #         '-moz-border-radius': '10px', 
      #         opacity: .6, 
      #         color: '#fff' 
      #       } 
      #     })
      # })
    )
)(jQuery)