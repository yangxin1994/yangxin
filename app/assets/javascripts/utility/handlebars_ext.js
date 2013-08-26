//= require handlebars.runtime

Handlebars.registerHelper('iterateTo', function(bound, options) {
	var retlist = [];
	for (var i = 0; i < bound; i++) {
		retlist.push(options.fn(i));
	};
	return retlist.join('');
});
Handlebars.registerHelper('add', function(v1, v2, options) {
	return options.fn(v1 + v2);
});