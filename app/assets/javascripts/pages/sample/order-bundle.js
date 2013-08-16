//=require ui/widgets/od_popup
jQuery(function($) {
	$("#order-cancel").click(function() {
		$(this).attr("disabled", "disabled");
		$.putJSON(
			'/orders/' + window._id + '/cancel.json',
			{},
			function(retval) {
				$("#order-cancel").removeAttr("disabled");
				if(retval.success) {
					$.od.odPopup({popupStyle: "quillme", title: "提示", content: "取消成功！", confirm: function() {
						window.location.reload();
					}});
				} else {
					$.od.odPopup({popupStyle: "quillme", title: "提示", content: "取消出错 :(.<br/>错误代码：" + retval.value.error_code});
				}
			}			
		);
	});
});