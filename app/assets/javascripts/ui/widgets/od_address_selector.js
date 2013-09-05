//=require ./_base
//=require ./_templates/od_address_selector
 
/* ================================
 * The address selector widget
 * ================================ */

(function($) {

	var provinces = null, cities = null, towns = null;
	function _getProvinces(callback) {
		callback = callback || function() {};
		if(provinces) {
			callback(provinces);
		} else {
			$.getJSON('/utility/address/provinces.json', function(retval) {
				provinces = retval || [];
				callback(provinces);
			});
		}
	};
	function _getCities(province_id, callback) {
		callback = callback || function() {};
		cities = cities || {};
 		if(cities[province_id]) {
			callback(cities[province_id]);
		} else {
			$.getJSON('/utility/address/cities.json', { province_id:province_id }, function(retval) {
				cities[province_id] = retval || [];
				callback(cities[province_id]);
			});
		}
	};
	function _getTowns(city_id, callback) {
		callback = callback || function() {};
		towns = towns || {};
 		if(towns[city_id]) {
			callback(towns[city_id]);
		} else {
			$.getJSON('/utility/address/towns.json', { city_id: city_id }, function(retval) {
				towns[city_id] = retval || [];
				callback(towns[city_id]);
			});
		}
	};
	
	$.odWidget('odAddressSelector', {
		
		/* The default setting for plugin
		 * ================================ */
		options: {
			precision: 3,			// 0. province, 1. city, 2. town, 3. detail
			has_postcode: false,
			value: {
				address: -1,
				detail: '',
				postcode: ''
			}
		},
		
		/* Set up the widget
		 * ================================ */
		_createEl: function() {
			this.element = this.hbs(this.options);
			this._province_slt = this._find('.address-province');
			this._city_slt = this._find('.address-city');
			this._town_slt = this._find('.address-town');
			this._detail_ipt = this._find('.address-detail');
			this._postcode_ipt = this._find('.address-postcode');
			if(this.options.precision >= 0) {
				this._province_slt.show();
				if(this.options.precision >= 1) {
					this._city_slt.show();
					if(this.options.precision >= 2) {
						this._town_slt.show();
						if(this.options.precision >= 3) {
							this._detail_ipt.show().placeholder();
						}
					}
				}
			}
			if(this.options.has_postcode)
				this._postcode_ipt.show().placeholder();

			// setup value
			this.val(this.options.value);
		},
		_province_slt: null,
		_city_slt: null,
		_town_slt: null,
		_detail_ipt: null,
		_postcode_ipt: null,

		_setupProvince: function() {
			this._province_slt.empty();
			this._province_slt.unbind('change');
			$('<option value="-1" />').text('- 加载中 -').appendTo(this._province_slt);
			_getProvinces($.proxy(function(provinces) {
				// setup dom
				this._province_slt.empty();
				$('<option value="-1" />').text('- 请选择 -').appendTo(this._province_slt);
				$.each(provinces, $.proxy(function(i, v) {
					$('<option value="' + v[0] + '" />').text(v[1]).appendTo(this._province_slt);
				}, this));
				// set change event
				this._province_slt.change($.proxy(function() {
					this._setupCities();
				}, this));
				// set value
				if(this.options.value.address > 0)
					this._province_slt.val(this.options.value.address >> 12 << 12);
				// setup cities
				this._setupCities();
			}, this));
		},

		_setupCities: function() {
			this._city_slt.empty();
			this._city_slt.unbind('change');
			var province_id = this._province_slt.val();
			if(province_id < 0) {
				$('<option value="-1" />').text('- 请选择 -').appendTo(this._city_slt);
				this._setupTowns();
			} else {
				$('<option value="-1" />').text('- 加载中 -').appendTo(this._city_slt);
				_getCities(province_id, $.proxy(function(cities) {
					// setup dom
					this._city_slt.empty();
					$('<option value="-1" />').text('- 请选择 -').appendTo(this._city_slt);
					$.each(cities, $.proxy(function(i, v) {
						$('<option value="' + v[0] + '" />').text(v[1]).appendTo(this._city_slt);
					}, this));
					// set change event
					this._city_slt.change($.proxy(function() {
						this._setupTowns();
					}, this));
					// set value
					if(this.options.value.address > 0)
						this._city_slt.val(this.options.value.address >> 6 << 6);
					// setup town
					this._setupTowns();
				}, this));
			}
		},

		_setupTowns: function() {
			this._town_slt.empty();
			this._town_slt.unbind('change');
			var city_id = this._city_slt.val();
			if(city_id < 0) {
				$('<option value="-1" />').text('- 请选择 -').appendTo(this._town_slt);
			} else {
				$('<option value="-1" />').text('- 加载中 -').appendTo(this._town_slt);
				_getTowns(city_id, $.proxy(function(towns) {
					// setup dom
					this._town_slt.empty();
					$('<option value="-1" />').text('- 请选择 -').appendTo(this._town_slt);
					$.each(towns, $.proxy(function(i, v) {
						$('<option value="' + v[0] + '" />').text(v[1]).appendTo(this._town_slt);
					}, this));
					// set value
					if(this.options.value.address > 0)
						this._town_slt.val(this.options.value.address);
				}, this));
			}
		},

		val: function(value) {
			if(value == undefined) {
				var answer = {};
				// precision: 3,			// 0. province, 1. city, 2. town, 3. detail
				switch(this.options.precision) {
					case 0: answer.address = this._province_slt.val(); break;
					case 1: answer.address = this._city_slt.val(); break;
					default: answer.address = this._town_slt.val(); break;
				}
				if(this.options.precision == 3)
					answer.detail = this._detail_ipt.val();
				if(this.options.has_postcode)
					answer.postcode = this._postcode_ipt.val();
				return answer;
			} else {
				this.options.value = value;
				this._setupProvince();
				this._detail_ipt.val(this.options.value.detail);
				this._postcode_ipt.val(this.options.value.postcode);
			}
		}
		
	});
	
})(jQuery);
