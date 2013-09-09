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
});