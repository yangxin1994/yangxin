jQuery(function($) {
	if ($('.mobile').length > 0 ){
		$.each($('.mobile'), function(index,item){	
      if ($.trim($(item).text()).length > 0){
        $.ajax({
          type: 'GET',
          dataType: 'json',
          timteout: 10000,
          url: '/users/get_mobile_area.json?m='+$.trim($(item).text())
        }).always(function(data){
          if (data.responseText != undefined){
            $(item).after('<span style="padding-left: 30px;">'+data.responseText+'</span>')
          }
        });
      }
    })
	}
})