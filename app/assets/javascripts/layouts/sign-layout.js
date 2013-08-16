jQuery(function($) {
	var error_dom = $('#error_prompt');
	window.showError = function(html, target, top, left) {
		target = $(target);
		if(target.is('input') || target.is('textarea')) {
			target.select();
		}
		$('.error-prompt-txt', error_dom).html(html);
		error_dom.css({
			top: ((top != undefined ? top : 0) + target.offset().top - 3 + (target.outerHeight() - error_dom.height()) / 2) + 'px',
			// left: (target.offset().left - 3 + (target.outerWidth() - error_dom.width()) / 2) + 'px',
			left: ((left != undefined ? left : 0) + target.parent('p').offset().left + 285) + 'px'
		}).fadeIn('fast');
	};
	window.hideError = function() {
		$('.error-prompt-txt', error_dom).html('');
		error_dom.hide();
	};
	$('.close-error', error_dom).click(hideError);
});