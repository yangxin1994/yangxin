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

  (function(){
    // 城市选择 切换季度
    var prev = $('#quarter .prev'); //上季度
    var next = $('#quarter .next'); //下季度
    var content = $('#quarter .cur-quarter');

    var getYearWeek = function (a, b, c) { 
      var date1 = new Date(a, parseInt(b) - 1, c), date2 = new Date(a, 0, 1), 
      d = Math.round((date1.valueOf() - date2.valueOf()) / 86400000); 
      return Math.ceil( (d + ((date2.getDay() + 1) - 1)) / 7 ); 
    };

    var today = new Date();//获取当前时间
    var y = today.getFullYear();
    var m = today.getMonth()+1;
    var d = today.getDate();
    var quarter = ""; //获取当前季度
    var result = getYearWeek(y, m, d);
    if (m <4) {
     quarter = 1;
     week = result;
    } else if (m < 7) {
     quarter = 2;
     week = result - getYearWeek(y, 4, 1);
     var day = new Date(y, 4, 1);
     if (day.getDay() > 1) {
      week += 1;
     }
    } else if (m < 10) {
     quarter = 3;
     week = result - getYearWeek(y, 7, 1);
     var day = new Date(y, 7, 1);
     if (day.getDay() > 1) {
      week += 1;
     }
    } else {
     quarter = 4;
     week = result - getYearWeek(y, 10, 1);
     var day = new Date(y, 10, 1);
     if (day.getDay() > 1) {
      week += 1;
     }
    }
    content.html(y+'年第'+quarter+'季度');  


  })();

});









