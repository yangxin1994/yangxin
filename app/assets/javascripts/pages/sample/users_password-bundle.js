jQuery(function($) {  
  $('.actions').on("click", ".btn.btn-submit",function(){
    var opwd= $.trim($('#opwd').val());
    var npwd = $.trim($('#npwd').val());
    var cpwd = $.trim($('#cpwd').val());

    if( opwd.length == 0 ) {
        $('#opwd').addClass('error');
        $('.alert-opwd').removeClass('alert-hide');
    }
    if( npwd.length == 0 ) {
        $('#npwd').addClass('error');
        $('.alert-npwd').removeClass('alert-hide');
    }
    if( cpwd.length == 0 ) {
        $('#cpwd').addClass('error');
        $('.alert-cpwd').removeClass('alert-hide');
    }
    else {
      if( cpwd != npwd ) {
            $('#cpwd').addClass('error');
            $('.alert-cpwd2').removeClass('alert-hide');
        }  
      }

    if ($('.error').length > 0) {
      return false;
    };

    $.ajax({
      type: 'PUT',
      url: '/users/setting/password.json',
      data: {
        old_password: opwd,
        new_password: npwd
      }
    }).done(function(data){
      // console.log(data);
      if (data.success && data.value){
        $.popupFancybox({success: true, cont: "登录密码修改成功！"});
        $('input[type=password]').val('');
      }else {
        $.fancybox($('#popup-fail'));
        if (data.value.error_code == 'error_11') {
          $.popupFancybox({cont: "操作失败，请保证原密码正确！"});
        }
      }
    });
  });

  $('#opwd').blur(function(){
    if( $.trim($(this).val()).length == 0 ) {
      $(this).addClass('error');
      $('.alert-'+$(this).attr('id')).removeClass('alert-hide');
    }else{
      $(this).removeClass('error');
      $('.alert-'+$(this).attr('id')).addClass('alert-hide');
    }
  });

  $('#npwd').blur(function(){
    var npwd = $.trim($('#npwd').val());
    var cpwd = $.trim($('#cpwd').val());
    // $('.alert-cpwd2').addClass('alert-hide');
    // $('#cpwd').removeClass('error');
    
    if( npwd.length == 0 ) {
        $('#npwd').addClass('error');
        $('.alert-npwd').removeClass('alert-hide');
    }
    else {
      $('#npwd').removeClass('error');
      $('.alert-npwd').addClass('alert-hide');

      if( $.trim(cpwd) != "" && $.trim(cpwd) != $.trim(npwd) ) {
          $('#cpwd').addClass('error');
          $('.alert-cpwd2').removeClass('alert-hide');
      } else {
          $('.alert-cpwd2').addClass('alert-hide');
      }
    }
  });

  $('#cpwd').blur(function(){
    var npwd = $.trim($('#npwd').val());
    var cpwd = $.trim($('#cpwd').val());
    $('.alert-cpwd, .alert-cpwd2').addClass('alert-hide');

    if( cpwd.length == 0 ) {
        $('#cpwd').addClass('error');
        $('.alert-cpwd').removeClass('alert-hide');
    }
    else {
      if( cpwd != npwd ) {
            $('#cpwd').addClass('error');
            $('.alert-cpwd2').removeClass('alert-hide');
        }else{
          $('#cpwd').removeClass('error');
        }
      }
  });
});