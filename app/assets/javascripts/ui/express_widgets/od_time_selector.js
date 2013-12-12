//=require ./_base
//=require ./_templates/od_time_selector
 
/* ================================
 * The Time selector widget
 * ================================ */

(function($) {

	$.odWidget('odTimeSelector', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			format: 1,	// 0 - 6, 年、年月、年月日、年月日时分、月日、时分、时分秒
			min: $.util.MIN_TIME,	// include
			max: $.util.MAX_TIME,	// include
			// value: (new Date()).getTime(),
			value: null,
			onChange: function() {}
		},
		
		_min_date: null,
		_max_date: null,

		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			this._min_date = new Date(this.options.min);
			this._max_date = new Date(this.options.max);

			this.element = this.hbs(this.options);

			this._find('li').hide();
			var _show = $.proxy(function(from, to) {
				for (var i = from; i < to; i++) {
					this._find('li:eq(' + i + ')').show();
				};
			}, this);
			switch(this.options.format) {
				case 0: case 1:  case 2: _show(0, this.options.format + 1); break;
				case 3: _show(0, 5); break;
				case 4: _show(1, 3); break;
				case 5: _show(3, 5); break;
				case 6: _show(3, 6); break;
			}

			// setup selects
			this.val(this.options.value);
			// var init_date = new Date(this.options.value);
			// if(this.options.format < 4)
			// 	this._setupYear(init_date.getFullYear());
			// if(this.options.format > 0 && this.options.format < 5)
			// 	this._setupMonth(init_date.getMonth());
			// if(this.options.format > 1 && this.options.format < 5)
			// 	this._setupDate(init_date.getDate());
			// if(this.options.format == 3 || this.options.format == 5 || this.options.format == 6) {
			// 	this._setupHours(init_date.getHours());
			// 	this._setupMinutes(init_date.getMinutes());
			// }
			// if(this.options.format == 6)
			// 	this._setupSeconds(init_date.getSeconds());
		},

		_select: function(value, value_from, value_to, get_label_fun) {
			var $select = $('<select><option value="-1">- 请选择 -</option></select>');
			for (var i = value_from; i < value_to; i++) {
				$('<option value=' + i + '>' + get_label_fun(i) + '</option>').appendTo($select);
			};
			$select.val(value);
			return $select;
		},

		_setupYear: function(value) {
			if(this.options.format > 3) return;

			var year_min = this._min_date.getFullYear(), 
			    year_max = this._max_date.getFullYear();

			this._find('.ts-year select').remove();
			var $select = this._select(value, year_min, year_max + 1, function(v) { 
				return v; 
			}).prependTo(this._find('.ts-year'));
			$select.change($.proxy(function() {
				this._setupMonth();
				this._setupDate();
				this._setupHours();
				this._setupMinutes();
				this._setupSeconds();

				if(this.options.format == 0 && this.options.onChange)
					this.options.onChange(this.val());
			}, this));
		},

		_setupMonth: function(value) {
			if(this.options.format < 1 || this.options.format > 4) return;

			var month_min = 0, month_max = 11;
			if(this.options.format == 4) {
				month_min = this._min_date.getMonth(); 
				month_max = this._max_date.getMonth();
			} else {
				var y = parseInt(this._find('.ts-year select').val());
				if(isNaN(y)) y = -1;
				if(y == -1) {
					month_max = -1;
				} else {
					switch(y) {
						case this._min_date.getFullYear(): month_min = this._min_date.getMonth(); break;
						case this._max_date.getFullYear(): month_max = this._max_date.getMonth(); break;
					}
				}
			}

			this._find('.ts-month select').remove();
			var $select = this._select(value, month_min, month_max + 1, function(v) { 
				return v + 1; 
			}).prependTo(this._find('.ts-month'));
			$select.change($.proxy(function() {
				this._setupDate();
				this._setupHours();
				this._setupMinutes();
				this._setupSeconds();

				if(this.options.format == 1 && this.options.onChange)
					this.options.onChange(this.val());
			}, this));
		},

		_setupDate: function(value) {
			if(this.options.format < 2 || this.options.format > 4) return;

			var y = parseInt(this._find('.ts-year select').val());
			if(isNaN(y)) y = -1;
			var m = parseInt(this._find('.ts-month select').val());
			if(isNaN(m)) m = -1;
			var date_min = 1, date_max = 31;
			switch(m) {
				case 3: case 5: case 8: case 10: date_max = 30; break;
				case 1:
					date_max = ((y > 0) && (((y % 4 == 0) && (y % 100 != 0)) || (y % 400 == 0))) ? 29 : 28;
					break;
			}

			if(m == -1) {
				date_max = 0;
			} else {
				switch(m) {
					case this._min_date.getMonth(): date_min = this._min_date.getDate(); break;
					case this._max_date.getMonth(): date_max = this._max_date.getDate(); break;
				}
			}

			this._find('.ts-date select').remove();
			var $select = this._select(value, date_min, date_max + 1, function(v) { 
				return v; 
			}).prependTo(this._find('.ts-date'));
			$select.change($.proxy(function() {
				this._setupHours();
				this._setupMinutes();
				this._setupSeconds();

				if((this.options.format == 2 || this.options.format == 4) && this.options.onChange)
					this.options.onChange(this.val());
			}, this));
		},

		_setupHours: function(value) {
			if(this.options.format != 3 && this.options.format != 5 && this.options.format != 6) return;

			var hour_min = 0, hour_max = 23;
			if(this.options.format == 3) {
				var d = parseInt(this._find('.ts-date select').val());
				if(isNaN(d)) d = -1;
				if(d == -1) {
					hour_max = -1;
				} else {
					switch(d) {
						case this._min_date.getDate(): hour_min = this._min_date.getHours(); break;
						case this._max_date.getDate(): hour_max = this._max_date.getHours(); break;
					}
				}
			} else {
				hour_min = this._min_date.getHours(); 
				hour_max = this._max_date.getHours();
			}

			this._find('.ts-hour select').remove();
			var $select = this._select(value, hour_min, hour_max + 1, function(v) { 
				return v; 
			}).prependTo(this._find('.ts-hour'));
			$select.change($.proxy(function() {
				this._setupMinutes();
				this._setupSeconds();
			}, this));
		},

		_setupMinutes: function(value) {
			if(this.options.format != 3 && this.options.format != 5 && this.options.format != 6) return;

			var minute_min = 0, minute_max = 59;
			var h = parseInt(this._find('.ts-hour select').val());
			if(isNaN(h)) h = -1;
			if(h == -1) {
				minute_max = -1;
			} else {
				switch(h) {
					case this._min_date.getHours(): minute_min = this._min_date.getMinutes(); break;
					case this._max_date.getHours(): minute_max = this._max_date.getMinutes(); break;
				}
			}

			this._find('.ts-minute select').remove();
			var $select = this._select(value, minute_min, minute_max + 1, function(v) { 
				return v; 
			}).prependTo(this._find('.ts-minute'));
			$select.change($.proxy(function() {
				this._setupSeconds();

				if((this.options.format == 3 || this.options.format == 5) && this.options.onChange)
					this.options.onChange(this.val());
			}, this));
		},

		_setupSeconds: function(value) {
			if(this.options.format != 6) return;

			var second_min = 0, second_max = 59;
			var m = parseInt(this._find('.ts-minute select').val());
			if(isNaN(m)) m = -1;
			if(m == -1) {
				second_max = -1;
			} else {
				switch(m) {
					case this._min_date.getMinutes(): second_min = this._min_date.getSeconds(); break;
					case this._max_date.getMinutes(): second_max = this._max_date.getSeconds(); break;
				}
			}

			this._find('.ts-second select').remove();
			var $select = this._select(value, second_min, second_max + 1, function(v) { 
				return v; 
			}).prependTo(this._find('.ts-second'));
			$select.change($.proxy(function() {
				if(this.options.format == 6 && this.options.onChange)
					this.options.onChange(this.val());
			}, this));
		},

		getValue: function() {
			console.warn('The getValue method of time selector is deprecated. Please use "val" instead.');
			return this.val();
		},

		val: function(milliseconds) {
			if(milliseconds === undefined) {
				var y = parseInt(this._find('.ts-year select').val()),
					m = parseInt(this._find('.ts-month select').val()),
					d = parseInt(this._find('.ts-date select').val()),
					h = parseInt(this._find('.ts-hour select').val()),
					mi = parseInt(this._find('.ts-minute select').val()),
					s = parseInt(this._find('.ts-second select').val());
				var ret_date = new Date(
					y >= 0 ? y : 2000, m >= 0 ? m : 0, d >= 0 ? d : 1, 
					h >= 0 ? h : 0, mi >= 0 ? mi : 0, s >= 0 ? s : 0, 
				0);
				return ret_date.getTime();
			} else {
				var is_null = (milliseconds === null);
				var date = new Date(milliseconds);
				if(this.options.format < 4)
					this._setupYear(is_null ? -1 : date.getFullYear());
				if(this.options.format > 0 && this.options.format < 5)
					this._setupMonth(is_null ? -1 : date.getMonth());
				if(this.options.format > 1 && this.options.format < 5)
					this._setupDate(is_null ? -1 : date.getDate());
				if(this.options.format == 3 || this.options.format == 5 || this.options.format == 6) {
					this._setupHours(is_null ? -1 : date.getHours());
					this._setupMinutes(is_null ? -1 : date.getMinutes());
				}
				if(this.options.format == 6)
					this._setupSeconds(is_null ? -1 : date.getSeconds());
			}
		},

		checkInput: function() {
			// Check whether use has selected all the time option or not
			var y = parseInt(this._find('.ts-year select').val()) || 0,
				m = parseInt(this._find('.ts-month select').val()) || 0,
				d = parseInt(this._find('.ts-date select').val()) || 0,
				h = parseInt(this._find('.ts-hour select').val()) || 0,
				mi = parseInt(this._find('.ts-minute select').val()) || 0,
				s = parseInt(this._find('.ts-second select').val()) || 0;
			// format: 1,	// 0 - 6, 年、年月、年月日、年月日时分、月日、时分、时分秒
			switch(this.options.format) {
				case 0: if(y < 0) return false; break;
				case 1: if(y < 0 || m < 0) return false; break;
				case 2: if(y < 0 || m < 0 || d < 0) return false; break;
				case 3: if(y < 0 || m < 0 || d < 0 || h < 0 || mi < 0) return false; break;
				case 4: if(m < 0 || d < 0) return false; break;
				case 5: if(h < 0 || mi < 0) return false; break;
				case 6: if(h < 0 || mi < 0 || s < 0) return false; break;
			}
			return true;
		}

	});
	
})(jQuery);
