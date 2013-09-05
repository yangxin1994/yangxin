//=require ui/widgets/od_popup
//=require jquery.stickyscroll

jQuery(function($) {
	// sticky header
	if(!$.browser.msie) {
		$('#sf_banner_sticky').stickyScroll({container: $('#sf_banner')});
	}
});