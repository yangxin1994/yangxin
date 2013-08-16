//=require jquery.placeholder
//=require utility/ajax

$(function(){

  $('.form  input').focus(function(){
    $(this).removeClass('error')
    $(this).next('span').remove();
  })

  $('.login_btn').click(function(){
    var obj = $('[name="username"]');
    var account   = obj.val();
    var pass      = $('[name="password"]').val();
    var thid_id   = $('.rember_me').is(':checked') ?  true : false
    var signed_in = null
    if(account.length < 1){
      obj.addClass('error')
    }else if(pass.length < 1){
      $('[name="password"]').addClass('error')
    }else{
      login(obj,account,pass)  
    }

    
  })


  document.onkeydown = function(e){ 
    if(!e) e = window.event;//火狐中是 window.event 
      if((e.keyCode || e.which) == 13){ 
        $('.login_btn').click()
    } 
  }  	


  function login(obj,account,pass,thid_id,signed_in){
      $('.login_btn').html('登录中...')
      $('.login_btn').attr('disabled',true)
      $.postJSON('/account/login.json',{email_mobile:account,password:pass,third_party_user_id:thid_id,permanent_signed_in:signed_in},function(retval){
        if(retval.success){
        	location.href = '/account/after_sign_in' + ($.util.param('ref') ? ('?ref=' + $.util.param('ref')) : '');
        }else{
          $('.login_btn').attr('disabled',false)
          $('.login_btn').html('<span>登录</span>')
          generate_error_message(retval.value['error_code'])
        }
      })  	
  }

  function generate_error_message(error_type){
    var err_notice = null
    switch(error_type){
      case 'error_3':
          err_notice = "<span class='notice'>账户未激活,<a href='/account/sign_up'>立即激活</a></span>"
        break;
      case 'error_4':
        err_notice = "<span class='notice'>账户不存在 ,<a href='/account/sign_up'>立即注册</a></span>"
        break;
      case 'error_11':
        err_notice = "<span class='notice'>密码错误</span>"
        break;
      case 'error_24':
        err_notice = "<span class='notice'>账户未激活,您可以<a href='/account/sign_up'>重新激活</a></span>"
        break;
    }
    if(error_type == 'error_11'){
      if($('[name="password"]').next('span.notice').length < 1){
        $('[name="password"]').after(err_notice);   
      } 
    }else{
      if($('[name="username"]').next('span.notice').length < 1){
        $('[name="username"]').after(err_notice);    
      }
    }
    
  }












})