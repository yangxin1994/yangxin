//=require ui/widgets/od_popup

jQuery(function($) {
	var css_dom = null;
	function load_css(name) {
		if(css_dom) css_dom.remove();
		css_dom = $('<link rel="stylesheet" href="/assets/quill/views/filler_styles/' + name + '-bundle.css" type="text/css" />');
		$('head').append(css_dom);
	};

	var slide_block_width = $(".slide-block").width() + 4;		//border-width: 2px
	var max_slide_width = $(".slide").width() - slide_block_width * 4;
	var position = 0;
	if(window.stylesheet == "" || null)
		window.stylesheet = "default";
	load_css(window.stylesheet);

	$('.slide-block').each(function() {
		$(this).data("selected", false);
		if($(this).children('h2').attr("id") == window.stylesheet) {
			$(this).data("selected", true);
			$(this).addClass('selected');
			$(this).css({"borderColor": "#FBB03B"});

			var index = $(this).index();
			position = (index - 3) * slide_block_width;
			if(position <= 0)
				position = 0;
			$(".slide").css("left", -position);	
		};
	});

	$('.slide-block').hover (
		function() {
			if(!$(this).data("selected"))
    			$(this).animate({"borderColor": "#F5C000"}, "fast");
		},
		function() {
			if(!$(this).data("selected"))
    			$(this).animate({"borderColor": "#F2F2F2"}, "fast");		
		}
	);

	$('.slide-container').hover (
		function() {},
		function() {
			$('.slide-block').stop(true, true);
			$('.slide-block').each(function() {
				$(this).css("borderColor", "#F2F2F2");
				if($(this).data("selected"))
					$(this).css("borderColor", "#F5C000");
			})
		}
	);

	$('.slide-block').click(function() {
		$('.selected').data("selected", false);
		$(this).data("selected", true);
		$('.selected').css({"borderColor": "#F2F2F2"});
		$('.selected').removeClass('selected');
		$(this).addClass('selected');
		$(this).css({"borderColor": "#FBB03B"});

		var new_name = $(this).children('h2').attr("id");
		$.putJSON('/questionaires/' + window.survey_id + '/customization', {
			stylesheet: new_name
		}, function(retval) {
			if(retval.success) {
				//$('#name').text(new_name);
				// $.od.odPopup({title: "提示", content: "更新样式成功！"});
			} else {
				// $.od.odPopup({title: "提示", content: "更新样式出错 :(.<br/>错误代码：" + retval.value.error_code});
			}
		});
		load_css(new_name);
	});

	$(".leftbutton").click(function(){
		if(position > 0){
			$(".slide").animate({"left": "+="+slide_block_width+"px"}, 500, "easeOutExpo");
			position -= slide_block_width;			
		}
	});

	$(".rightbutton").click(function(){
		if(position < max_slide_width){
			$(".slide").animate({"left": "-="+slide_block_width+"px"}, 500, "easeOutExpo");
			position += slide_block_width;
		}
	});	

});