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

  (function(){
    //选择城市 完成/审核通过 切换
    $('#suffice-finished').on('click', '#suffice', function(event) {
      $('.city-list').toggleClass('finished');
    });
  })();
 
  (function(){
     // 查看问卷 完成/审核通过 切换
    $('#suffice-finished').on('click', '#suffice', function(event) {
      $('.answer-list').toggleClass('finished');
    });
     // 下拉列表
    $('.answer-list').on('click','.survey',function(event) {
      $(this).parent().siblings('dd').slideToggle(400);
    });
  })();

});
