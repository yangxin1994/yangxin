//=require utility/ajax
$(function(){

  var uri = location.href;
  var params = uri.substring(uri.indexOf('?')+5,uri.length);

  $('a.re_mail').click(function(){
    re_mail($(this),params)
  })


  function re_mail(obj,link,params){
    $.getJSON('/account/re_mail_after_expired.json',{k:params},function(retval){
      if(retval.success){
        $('.re_notice').show();
      }else{
        console.log(retval)
      }
    })      
  }

})

