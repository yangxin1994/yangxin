jQuery(function($) {
	if ($('.mobile').length > 0 ){
		$.each($('.mobile'), function(index,item){	
      if ($.trim($(item).text()).length > 0){
        $.getJSON('/users/get_mobile_area.json?m='+$.trim($(item).text()), function(data){
          // console.log(data);
          if (data.success){
            $(item).after('<span style="padding-left: 30px;">'+data.value+'</span>')
          }
        });
      }
    })
	}
})