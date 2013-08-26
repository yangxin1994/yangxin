jQuery(function($) {    
	// *************** functions ******************

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

	function _getPovinceCode(code){
		return parseInt(code) >> 12 << 12;
	}

	function _getCityCode(code){
		return parseInt(code) >> 6 << 6;
	}

	function _setupAddressSelector(jq_obj, code){
		var default_code = parseInt(code);
		var provice_code = _getPovinceCode(default_code);
		var city_code = _getCityCode(default_code);
		// console.log(default_code+',  '+provice_code+',  '+city_code);

		_getProvinces(function(provices){
			var initProvices='';
			$.each(provices, function(index, item){
				initProvices = initProvices + '<li name="'+item[0]+'">'+item[1]+'</li>';

				if (item[0] == provice_code){
					jq_obj.find('.provice .select-txt').text(item[1])
						.attr('title', item[1]).attr('name', item[0]);
				}
			});
			jq_obj.find('.provice ul').empty().append(initProvices);
		});

		_getCities(provice_code, function(cities){
			// console.log(provices);
			var initCities='';
			$.each(cities, function(index, item){
				initCities = initCities + '<li name="'+item[0]+'">'+item[1]+'</li>';

				if (item[0] == city_code){
					jq_obj.find('.city .select-txt').text(item[1])
						.attr('title', item[1]).attr('name', item[0]);
				}
			});
			jq_obj.find('.city ul').empty().append(initCities);
		});

		_getTowns(city_code, function(towns){
			// console.log(provices);
			var initTowns='';
			$.each(towns, function(index, item){
				initTowns = initTowns + '<li name="'+item[0]+'">'+item[1]+'</li>';

				if (item[0] == default_code){
					jq_obj.find('.town .select-txt').text(item[1])
						.attr('title', item[1]).attr('name', item[0]);
				}
			});
			jq_obj.find('.town ul').empty().append(initTowns);
		});
	}

	function _checkItemChange(jq_click_li, jq_select){
		var _click_name = jq_click_li.attr('name');
		var _select_txt = jq_select.find('.select-txt');
		$('.select ul').css('display', 'none');
		jq_select.removeClass('active');
		// if click one is the same as selected item, return false
		if (_click_name == _select_txt.attr('name')){
			return false;
		}
		var _click_txt = jq_click_li.text();
		if (_click_name != undefined) {
			_select_txt.text(jq_click_li.text()).attr('name', _click_name).attr('title',_click_txt);
		}else{
			_select_txt.text(jq_click_li.text());
		}
		return true;
	}

	function _noSelected(jq_select){
		jq_select.find('.select-txt').text('请选择..').attr('name', "-1");
	}

	function _addressLoading(jq_select){
		jq_select.find('.select-txt').text('加载中..').attr('name', "-1");
		jq_select.find('ul').empty();
	}

	// *******************************************

	// init address-area
	if ($('#address-area').length > 0) {
		_getProvinces(function(provices){
			// console.log(provices);
			var initProvices='';
			$.each(provices, function(index, item){
				initProvices = initProvices + '<li name="'+item[0]+'">'+item[1]+'</li>';
			});
			$('#address-area .provice ul').empty().append(initProvices);
		});

		$('#address-area .provice ul').unbind('click').on('click', 'li', function(){
			if ( !_checkItemChange($(this), $('#address-area .provice')) ){
				return false;
			}else{
				_addressLoading($('#address-area .city'));
				_addressLoading($('#address-area .town'));
			}
			// console.log($('#address-area .provice .select-txt').attr('name')+'..............'+ $('#address-area .provice .select-txt').text())
			var v_code = $('#address-area .provice .select-txt').attr('name');
			$('#address-code').val(v_code);

			_getCities(v_code, function(cities){
				// console.log(provices);
				_noSelected($('#address-area .city'));
				_noSelected($('#address-area .town'));

				var initCities='';
				$.each(cities, function(index, item){
					initCities = initCities + '<li name="'+item[0]+'">'+item[1]+'</li>';
				});
				$('#address-area .city ul').empty().append(initCities);
			});
		})

		$('#address-area .city ul').unbind('click').on('click', 'li', function(){
			if ( !_checkItemChange($(this), $('#address-area .city')) ){
				return false;
			}else{
				_addressLoading($('#address-area .town'));
			}
			// console.log($('#address-area .city .select-txt').attr('name')+', '+ $('#address-area .city .select-txt').text())
			var v_code = $('#address-area .city .select-txt').attr('name');
			$('#address-code').val(v_code);

			_getTowns(v_code, function(towns){
				// console.log(provices);
				_noSelected($('#address-area .town'));

				var initTowns='';
				$.each(towns, function(index, item){
					initTowns = initTowns + '<li name="'+item[0]+'">'+item[1]+'</li>';
				});
				$('#address-area .town ul').empty().append(initTowns);
			});
		})

		$('#address-area .town ul').unbind('click').on('click', 'li', function(){
			if ( !_checkItemChange($(this), $('#address-area .town')) ){
				return false;
			}
			// console.log($('#address-area .town .select-txt').attr('name')+', '+ $('#address-area .town .select-txt').text())
			var v_code = $('#address-area .town .select-txt').attr('name');
			$('#address-code').val(v_code);
		})
	}

	_setupAddressSelector($('#address-area'), $('#address-code').val());
	
	$('.actions').on("click", ".btn.btn-submit",function(){
		var receiver = $.trim($('#receiver').val());
		var address = $.trim($('#address-code').val());
		var street_info = $.trim($('#street').val());
		var mobile = $.trim($('#mobile').val());
		var postcode = $.trim($('#postcode').val());

		if( receiver.length == 0 ) {
			$('#receiver').addClass('error');
			$('.alert-receiver').removeClass('alert-hide');
		}

		if( street_info.length == 0 ) {
			$('#street').addClass('error');
			$('.alert-street').removeClass('alert-hide');
		}
		if(!/^1[3|4|5|8][0-9]\d{8}$/.test(mobile) ) {
			$('#mobile').addClass('error');
			$('.alert-mobile').removeClass('alert-hide');
		}
		if(!/^[0-9]{6}$/.test(postcode) ) {
			$('#postcode').addClass('error');
			$('.alert-postcode').removeClass('alert-hide');
		}

		if ($('.error').length > 0) {
			return false;
		};

		$.ajax({
			type: 'PUT',
			url: '/users/setting/address.json',
			data: {
				receiver_info: {
					receiver: receiver,
					address: address,
					street_info: street_info,
					mobile: mobile,
					postcode: postcode
				}
			}
		}).done(function(data){
			// console.log(data);
			if (data.success && data.value){
				$.popupFancybox({success: true, cont: "收货地址更新成功！"});
			}else {
				$.popupFancybox({cont: "操作失败，请保证数据完整！"});
			}
		});
	});

	$('#receiver, #street').blur(function(){
		if( $.trim($(this).val()).length == 0 ) {
			$(this).addClass('error');
			$('.alert-'+$(this).attr('id')).removeClass('alert-hide');
		}else{
			$(this).removeClass('error');
			$('.alert-'+$(this).attr('id')).addClass('alert-hide');
		}
	});

	$('#mobile').blur(function(){
		if(!/^1[3|4|5|8][0-9]\d{8}$/.test($.trim($(this).val())) ) {
			$(this).addClass('error');
			$('.alert-mobile').removeClass('alert-hide');
		}else{
			$(this).removeClass('error');
			$('.alert-mobile').addClass('alert-hide');
		}
	});

	$('#postcode').blur(function(){
		if(!/^[0-9]{6}$/.test($.trim($(this).val())) ) {
			$(this).addClass('error');
			$('.alert-postcode').removeClass('alert-hide');
		}else{
			$(this).removeClass('error');
			$('.alert-postcode').addClass('alert-hide');
		}
	});

});