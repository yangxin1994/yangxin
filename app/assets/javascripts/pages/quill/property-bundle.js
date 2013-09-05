//=require ui/widgets/od_popup

var wel_editor;
KindEditor.ready(function(K) {
	wel_editor = K.create('#p-welcome', {items: ['fontname', 'fontsize', 'forecolor', 'hilitecolor', 'bold',
        'italic', 'underline', 'link', 'unlink', 'strikethrough', 'removeformat'], themeType: 'simple', resizeType: 1});
});

jQuery(function($) {
	$('.p-title input').blur(function(){
		$('.p-title b').html("");
		$('.p-title input').removeClass('error');
	});
	
	$('.property-bottom button').click(function() {
		var p_title = $('.p-title input').val();
		var pattern = new RegExp("^ *$");
		if(pattern.test(p_title)){
			$('.p-title b').text(" 请输入正确的标题");
			$('.p-title b').css({color: "red"});
			$('.p-title input').addClass('error');
			return;
		};

		wel_editor.sync();
		// clos_editor.sync();
		var properties = {
			title: p_title,
			subtitle: $('.p-subtitle input').val(),
			welcome: $('#p-welcome').val(),
			// closing: $('#p-closing').val(),
			header: $('.p-header input').val(),
			footer: $('.p-footer input').val()
		};
		$(this).attr("disabled", "disabled");		
		$.putJSON('/questionaires/' + window.survey_id + '/property.json', {
			properties: properties
		}, function(retval) {
			$('.property-bottom button').removeAttr("disabled");
			if(retval.success) {
				$.od.odPopup({title: "提示", content: "保存成功！"});
				$('#banner_survey_title').text(p_title);	// update title
			} else {
				$.od.odPopup({title: "提示", content: "保存出错 :(.<br/>错误代码：" + retval.value.error_code});
			}
		})
	});
});