//=require jquery.pageguide
//=require jquery.cookie
//=require express/views/survey_editor
//=require twitter/bootstrap/tooltip

jQuery(function($) {
	// scroll up
	$(window).scroll(function(){
		if ($(this).scrollTop() > 500) {
			$('.scrollup').fadeIn();
		} else {
			$('.scrollup').fadeOut();
		}
	});
	$('.scrollup').click(function(){
		$("html, body").animate({ scrollTop: 0 }, 600);
		return false;
	});

	// page guide
	var guide_cookie_key = window.uid + '_guide';
	if(!$.cookie(guide_cookie_key)) {
		var guide = {
			id: 'jQuery.PageGuide',
			title: '快速入门',
			steps: [ {
				target: '.sub-banner-menus > li:eq(0)',
				content: '【编辑问卷】在这里您可以创建修改和删除问题、设置问题间逻辑约束、设置问卷属性、对问卷进行权限控制和质量控制等。',
				direction: 'bottom'
			}, {
				target: '.sub-banner-menus > li:eq(2)',
				content: '【发布问卷】对问卷进行配额，将问卷答题链接分享给好友，邀请好友填写。',
				direction: 'bottom'
			}, {
				target: '.sub-banner-menus > li:eq(3)',
				content: '【查看结果】查看问卷的答案回收结果，在线进行统计分析，导出结果到 excel 和 spss，导出 word、ppt、pdf 版结果报告。',
				direction: 'bottom'
			}, {
				target: '.sub-banner-menus > li:eq(4)',
				content: '【预览问卷】点击此按钮可随时测试问卷的实际答题效果。',
				direction: 'bottom'
			}, {
				target: '.left-head',
				content: '【编辑器切换】点击“齿轮”按钮可切换至问卷的高级设置模式，点击“铅笔”按钮切换回问题编辑模式。',
				direction: 'right'
			}, {
				target: '.left-menus',
				content: '【问题菜单】点击不同问题按钮，或者将按钮拖放至右侧问卷内容区域，可实现向问卷中插入一道新问题的功能。',
				direction: 'right'
			}, {
				target: '.left-sidebar-pulldownBtn',
				content: '【更多题型】点击下拉箭头，展开更多题型。',
				direction: 'right'
			}]
		};
		$.pageguide(guide);
		$.pageguide('options', {
		});
		$.pageguide('open');
		// set cookie
		$.cookie(guide_cookie_key, 'true', {expires: 1000});
	}

});