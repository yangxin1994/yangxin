//= require "jquery.timeago"

jQuery(function($) {
  jQuery.timeago.settings.strings = {
    prefixAgo: null,
    prefixFromNow: "从现在开始",
    suffixAgo: "",
    suffixFromNow: null,
    seconds: "刚刚",
    minute: "刚刚",
    minutes: "%d 分钟之前",
    hour: "1 小时之前",
    hours: "%d 小时之前",
    day: "1 天之前",
    days: "%d 天之前",
    month: "1 个月之前",
    months: "%d 月之前",
    year: "1 年之前",
    years: "%d 年之前",
    numbers: [],
    wordSeparator: ""
  };
  
  $("abbr.timeago").timeago();

  $('td a.del').css('visibility','hidden');

  $('tbody tr').mouseover(function(){
    $(this).find('a.del').css('visibility','visible');
  }).mouseout(function(){
    $(this).find('a.del').css('visibility','hidden');
  })

  if ($('table tbody tr').length == 0 ){
    $('#delete-all').hide();
  }

  $('tr td').on("click", "a.del:not(.disabled)",function(){
    var _this = $(this);
    _this.addClass('disabled').text('删除中...');

      $.deleteJSON('/users/' + $(this).closest('tr').attr('id') + '/destroy_notification', function(data){
        // console.log(data);
        if (data.success && data.value){
          // console.log('success....');
          _this.closest('tr').remove();
          if ($('table tbody tr').length == 0 ){
            window.location.replace('/users/notifications');
          }
        }else {
          $.popupFancybox({cont: "操作失败，请刷新后重新操作"});
          _this.removeClass('disabled').text('删除');
        }
      }
    );
  });

  $('.notifications').on("click", "#delete-all",function(){
    $.deleteJSON('/users/notifications',function(data){
      // console.log(data);
      if (data.success && data.value){
        // console.log('success....');
        $('tbody tr, .pagination').remove();
        $('#delete-all').hide();
      }else {
        $.popupFancybox({cont: "操作失败，请刷新后重新操作"});
      }
    });
  });

});