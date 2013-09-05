//=require base64
//=require utility/ajax
$(function(){
    $('a.re_mail').click(function(){
      re_mail($(this).attr('data'))
    })


    function re_mail(params){
      $.postJSON('/surveys/make_rss_activate.json',{rss_channel:params},function(retval){
        if(retval.success){
          $('.re_notice').show();
        }else{
          console.log(retval.value)
        }
      })      
    }

})