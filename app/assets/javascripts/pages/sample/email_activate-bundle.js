$(function(){
    $('a.re_mail').click(function(){
      re_mail($(this).attr('data'))
    })


    function re_mail(params){
      $.getJSON('/account/re_mail.json',{k:params},function(retval){
        if(retval.success){
          $('.re_notice').show();
        }else{
          console.log(retval)
        }
      })      
    }

})