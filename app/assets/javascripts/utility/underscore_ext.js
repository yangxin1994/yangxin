/* ================================
 * Extend underscore
 * NOTE: underscore must load before this file is loaded
 * ================================ */
(function () {

	_.extend(_, {

		/* Find the index of an element in a list
		 * ============================== */
		findIndex: function(list, iterator) {
			if(!list) return -1;
			for (var i = 0; i < list.length; i++) {
				if(iterator(list[i]))
					return i;
			};
			return -1;
		}

	});

})()