//=require utility/ajax
jQuery(function($) {
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