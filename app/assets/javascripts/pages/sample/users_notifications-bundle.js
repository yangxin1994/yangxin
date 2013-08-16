//= require "/assets/jquery.timeago"

jQuery(function($) {
  jQuery.timeago.settings.strings = {
    prefixAgo: null,
    prefixFromNow: "从现在开始",
    suffixAgo: "之前",
    suffixFromNow: null,
    seconds: "不到 1 分钟",
    minute: "大约 1 分钟",
    minutes: "%d 分钟",
    hour: "大约 1 小时",
    hours: "大约 %d 小时",
    day: "1 天",
    days: "%d 天",
    month: "大约 1 个月",
    months: "%d 月",
    year: "大约 1 年",
    years: "%d 年",
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

  $('tr td').on("click", "a.del",function(){
    var _this = $(this);

    $.ajax({
      type: 'DELETE',
      url: '/users/notifications/'+$(this).closest('tr').attr('id')+'.json'
    }).done(function(data){
      // console.log(data);
      if (data.success && data.value){
        // console.log('success....');
        _this.closest('tr').remove();
      }else {
        $.popupFancybox({cont: "操作失败，请刷新后重新操作"});
      }
    });
  });

  $('.actions').on("click", ".del-all",function(){
    $.ajax({
      type: 'DELETE',
      url: '/users/notifications.json'
    }).done(function(data){
      // console.log(data);
      if (data.success && data.value){
        // console.log('success....');
        $('tbody tr, .pagination').remove();
      }else {
        $.popupFancybox({cont: "操作失败，请刷新后重新操作"});
      }
    });
  });

});