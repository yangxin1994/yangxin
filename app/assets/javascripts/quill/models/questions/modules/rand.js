/* ================================
 * Module to manipulate issue is_rand
 * ================================ */

$(function(){

	window.quill.modules.rand = function(model, issue) {
		if(!model || !issue) return;

		// set issue init value
		$.extend(issue, $.extend({
			is_rand: false
		}, issue));

		// extend handler
		var handler = {
			/* Random item manipulation.
			 * ============================ */
			setRandom: function(random) {
				if(issue.is_rand == random) return;
				issue.is_rand = random;
				model.trigger('change:issue:random', handler);
			}
		};

		return handler;

	};

});