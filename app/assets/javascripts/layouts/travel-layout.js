//=require config/quill
//=require ui/widgets/od_icon_buttons
//=require ui/widgets/od_tip
//=require ui/widgets/od_confirm_tip
//=require ui/widgets/od_autotip
//=require ui/plugins/od_button_text
//=require jquery.smartFloat
//=require jquery-powerFloat-min

//placeholder向下兼容
jQuery(function(){
  if( !('placeholder' in document.createElement('input')) ){   
    $('input[placeholder],textarea[placeholder]').each(function(){    
      var that = $(this),    
      text= that.attr('placeholder');    
      if(that.val()===""){    
        that.val(text).addClass('placeholder');    
      }    
      that.focus(function(){    
        if(that.val()===text){    
          that.val("").removeClass('placeholder');    
        }    
      })    
      .blur(function(){    
        if(that.val()===""){    
          that.val(text).addClass('placeholder');    
        }    
      })    
      .closest('form').submit(function(){    
        if(that.val() === text){    
          that.val('');    
        }    
      });    
    });    
  };
});

jQuery(function(){
  $('#suffice-finished').on('click', '#suffice', function(event) {
    $('.city-list').toggleClass('finished');
  });
});
