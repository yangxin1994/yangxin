//=require utility/ajax

jQuery(function($) {
  var content_editor;
  KindEditor.ready(function(K) {
    content_editor = K.create('#p-content', {items: ['fontname', 'fontsize', 'forecolor', 'hilitecolor', 'bold',
          'italic', 'underline', 'link', 'unlink', 'strikethrough', 'removeformat', 'image'], themeType: 'simple', resizeType: 1});
    $('.ke-container').css("width", "576px");
  });

  $('#email_list').click(function() {
    if($('#email_list').is(':checked')) {
      $('#email_content').slideDown();
    } else {
      $('#email_content').slideUp();
    }
  })

  $('.email_btn').click(function() {
    $('.ke-container').css("width", "576px");
    content_editor.sync();

    $('.email_btn').text('正在发送');

    $.postJSON('/admin/newsletters/send_netranking_newsletter.json', {
      file_path: $('#file-path').html(),
      subject: $('#subject').val(),
      email_list: $('#email_list').is(':checked'),
      send_from: $('#send_from').val(),
      domain: $('#domain').val(),
      email_content: $('#emails').val(),
      content: $('#p-content').val()
    }, function(retval) {
      $('.property-bottom button').removeAttr("disabled");
      if(retval.success) {
        alert_msg.show('success', "已成功发送邮件!")
        $('.email_btn').text('发送');
      } else {
        alert_msg.show('error', "失败 (╯‵□′)╯︵┻━┻")
      }
    })
  });

  $('.sms_btn').click(function() {

    $('.sms_btn').text('正在发送');

    $.postJSON('/admin/newsletters/send_sms.json', {
      mobile_list: $('#mobile_list').val(),
      sms_content: $('#sms_content').val()
    }, function(retval) {
      $('.property-bottom button').removeAttr("disabled");
      if(retval.success) {
        alert_msg.show('success', "已成功发送短信!")
        $('.sms_btn').text('发送');
      } else {
        alert_msg.show('error', "失败 (╯‵□′)╯︵┻━┻")
      }
    })

  });
});