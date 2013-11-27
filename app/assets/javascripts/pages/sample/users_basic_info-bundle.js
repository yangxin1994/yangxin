//= require ui/plugins/od_param
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

	function _setupSelector(jq_obj, value){
		if (value == "-1") {
			return false;
		}
		jq_obj.find('ul li').each(function(index, item){
			// console.log(index+', '+$(item).attr('name'))
			var _name = $(item).attr('name');
			var _txt = $(item).text();
			if (!!_name && _name.toString() == value){
				// console.log('.............')
				jq_obj.find('.select-content .select-txt')
					.attr('name',_name)
					.attr('title', _txt)
					.text(_txt);
				return false;
			}
		});
	}

	function _setupCompareSelector(jq_obj, value, compare_obj){
		if (parseInt(value) == -1) return;
		// var data_arr = value.split(/\D/);
		// date_arr = $.grep(date_arr, function(value){return value != "";});
		var data_arr = eval(value);
		$.each(compare_obj, function(index, item){
			// console.log(index)
			var item_data = index.split(/\D/)

			// console.log(item_data)
			// console.log(item_data[0]+', '+data_arr[1]+', '+item_data[1]+', '+data_arr[3])
			if ( parseInt(item_data[0]) <= parseInt(data_arr[0]) 
				&& parseInt(item_data[1]) >= parseInt(data_arr[1]) )
			{
				// console.log('...'+index+'.......')
				jq_obj.find('.select-content .select-txt')
					.attr('name',index).attr('title', item)
					.text(jq_obj.find('li[name='+index+']').text());
				return false;
			}
		})
	}

	function _setupAddressSelector(jq_obj, code){
		var default_code = parseInt(code);
		if (default_code == -1) return false;
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
        jq_select.find('.select-content').removeClass('active');
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

	// **************init page *************************

	// init select date values
	if ($('.select-date').length > 0) {
		var now = new Date();
		var now_year = now.getFullYear();
		$('.select-date .year ul').empty();
		var initYears='';
		for (var i = 0; i < 70; i++) {
			initYears=initYears + '<li name="'+(now_year-i)+'">'+(now.getFullYear()-i)+' 年</li>';
		};
		$('.select-date .year ul').append(initYears);

		$('.select-date .month ul').empty();      
		var initMonths='';
		for (var i = 1; i <= 12; i++) {
			initMonths=initMonths + '<li name='+ i +'>'+ i +' 月</li>';
		};
		$('.select-date .month ul').append(initMonths);

		$('.select-date .day ul').empty();
		var initDays='';
		for (var i = 1; i <= 31; i++) {
			initDays=initDays + '<li name="'+ i +'">'+ i +' 日</li>';
		};
		$('.select-date .day ul').append(initDays);     
		
		$('.select-date .month ul ').on('click','li',function(){
			// console.log(' change month')
			var current_month = parseInt($('.select-date .month .select-txt').attr('name'));
			var current_year = parseInt($('.select-date .year .select-txt').attr('name'));
			if($.inArray(current_month, [1,3,5,7,8,10,12]) != -1){
				for (var i = 29; i <= 31; i++) {
					if ($('.select-date .day ul li[name='+i+']').length == 0) {
						$('.select-date .day ul').append('<li name="'+ i +'">'+ i +' 日</li>');
					};
				};
			}                
			if ($.inArray(current_month,[4,6,9,11]) != -1){
				if ($('.select-date .day ul li[name=31]').length >= 0) {
					$('.select-date .day ul li[name=31]').remove();
				};
				for (var i = 29; i <= 30; i++) {
					if ($('.select-date .day ul li[name='+i+']').length == 0) {
						$('.select-date .day ul').append('<li name="'+ i +'">'+ i +' 日</li>');
					};
				};
				if (parseInt($('.select-date .day').find('.select-txt').attr('name')) == 31) {
					$('.select-date .day').find('.select-txt').attr('name', '1').text('1  日');
				};
			}
			if (current_month == 2){
				for (var i = 29; i <= 31; i++) {
					if ($('.select-date .day ul li[name='+i+']').length >= 0) {
						$('.select-date .day ul li[name='+i+']').remove();
					};
				};
				if((current_year % 100 == 0 && current_year % 400 == 0) || (current_year % 4 == 0)){
					$('.select-date .day ul').append('<li name="29">29 日</li>');
				}
				$('.select-date .day').find('.select-txt').attr('name', '1').text('1 日');
			}
		});
		$('.select-date .year ul').on('click','li',function(){
			// console.log(' change year')
			var current_month = parseInt($('.select-date .month .select-txt').attr('name'));
			if (current_month != 2){
				return false
			}
			// console.log(' ....')
			var current_year = parseInt($('.select-date .year .select-txt').attr('name'));
			// console.log('. '+current_year+'..'+(current_year % 100 == 0 && current_year % 400 == 0 || current_year % 4 == 0)+'........')
			if((current_year % 100 == 0 && current_year % 400 == 0) || (current_year % 4 == 0)){
				// console.log(' ....2....')
				if ($('.select-date .day ul li[name=29]').length == 0) {
					$('.select-date .day ul').append('<li name="29">29 日</li>');
				};

				if($.inArray(parseInt($('.select-date .day').find('.select-txt').attr('name')), [30,31]) != -1){
					$('.select-date .day').find('.select-txt').attr('name', '1').text('1 日');
				}
			}else{
				$('.select-date .day ul li[name=29]').remove();

				if($.inArray(parseInt($('.select-date .day').find('.select-txt').attr('name')),[29,30,31]) != -1){
					$('.select-date .day').find('.select-txt').attr('name', '1').text('1 日');
				}
			}
		});
	};

	// init born_address
	if ($('#born_address').length > 0) {
		_getProvinces(function(provices){
			// console.log(provices);
			var initProvices='';
			$.each(provices, function(index, item){
				initProvices = initProvices + '<li name="'+item[0]+'">'+item[1]+'</li>';
			});
			$('#born_address .provice ul').empty().append(initProvices);
		});

		$('#born_address .provice ul').unbind('click').on('click', 'li', function(){
			if ( !_checkItemChange($(this), $('#born_address .provice')) ){
				return false;
			}else{
				_addressLoading($('#born_address .city'));
				_addressLoading($('#born_address .town'));
			}
			// console.log($('#born_address .provice .select-txt').attr('name')+'..............'+ $('#born_address .provice .select-txt').text())
			var v_code = $('#born_address .provice .select-txt').attr('name');
			$('#born_address_value').val(v_code);

			_getCities(v_code, function(cities){
				// console.log(provices);
				_noSelected($('#born_address .city'));
				_noSelected($('#born_address .town'));

				var initCities='';
				$.each(cities, function(index, item){
					initCities = initCities + '<li name="'+item[0]+'">'+item[1]+'</li>';
				});
				$('#born_address .city ul').empty().append(initCities);
			});
		})

		$('#born_address .city ul').unbind('click').on('click', 'li', function(){
			if ( !_checkItemChange($(this), $('#born_address .city')) ){
				return false;
			}else{
				_addressLoading($('#born_address .town'));
			}
			// console.log($('#born_address .city .select-txt').attr('name')+', '+ $('#born_address .city .select-txt').text())
			var v_code = $('#born_address .city .select-txt').attr('name');
			$('#born_address_value').val(v_code);

			_getTowns(v_code, function(towns){
				// console.log(provices);
				_noSelected($('#born_address .town'));

				var initTowns='';
				$.each(towns, function(index, item){
					initTowns = initTowns + '<li name="'+item[0]+'">'+item[1]+'</li>';
				});
				$('#born_address .town ul').empty().append(initTowns);
			});
		})

		$('#born_address .town ul').unbind('click').on('click', 'li', function(){
			if ( !_checkItemChange($(this), $('#born_address .town')) ){
				return false;
			}
			// console.log($('#born_address .town .select-txt').attr('name')+', '+ $('#born_address .town .select-txt').text())
			var v_code = $('#born_address .town .select-txt').attr('name');

			$('#born_address_value').val(v_code);
		})
	}

	// init live_address
	if ($('#live_address').length > 0) {
		_getProvinces(function(provices){
			// console.log(provices);
			var initProvices='';
			$.each(provices, function(index, item){
				initProvices = initProvices + '<li name="'+item[0]+'">'+item[1]+'</li>';
			});
			$('#live_address .provice ul').empty().append(initProvices);
		});

		$('#live_address .provice ul').unbind('click').on('click', 'li', function(){
			if ( !_checkItemChange($(this), $('#live_address .provice')) ){
				return false;
			}else{
				_addressLoading($('#live_address .city'));
				_addressLoading($('#live_address .town'));
			}
			// console.log($('#live_address .provice .select-txt').attr('name')+'..............'+ $('#live_address .provice .select-txt').text())
			var v_code = $('#live_address .provice .select-txt').attr('name');
			$('#live_address_value').val(v_code);

			_getCities(v_code, function(cities){
				// console.log(provices);
				_noSelected($('#live_address .city'));
				_noSelected($('#live_address .town'));

				var initCities='';
				$.each(cities, function(index, item){
					initCities = initCities + '<li name="'+item[0]+'">'+item[1]+'</li>';
				});
				$('#live_address .city ul').empty().append(initCities);
			});
		})

		$('#live_address .city ul').unbind('click').on('click', 'li', function(){
			if ( !_checkItemChange($(this), $('#live_address .city')) ){
				return false;
			}else{
				_addressLoading($('#live_address .town'));
			}
			// console.log($('#live_address .city .select-txt').attr('name')+', '+ $('#live_address .city .select-txt').text())
			var v_code = $('#live_address .city .select-txt').attr('name');
			$('#live_address_value').val(v_code);

			_getTowns(v_code, function(towns){
				// console.log(provices);
				_noSelected($('#live_address .town'));

				var initTowns='';
				$.each(towns, function(index, item){
					initTowns = initTowns + '<li name="'+item[0]+'">'+item[1]+'</li>';
				});
				$('#live_address .town ul').empty().append(initTowns);
			});
		})

		$('#live_address .town ul').unbind('click').on('click', 'li', function(){
			if ( !_checkItemChange($(this), $('#live_address .town')) ){
				return false;
			}
			// console.log($('#live_address .town .select-txt').attr('name')+', '+ $('#live_address .town .select-txt').text())
			var v_code = $('#live_address .town .select-txt').attr('name');
			$('#live_address_value').val(v_code);
		})
	}

	// init other selector items
	var income_person = {"0_0":"无收入","0_2000":"2000以下","2000_3000":"2000-3000","3001_4000": "3001-4000", 
							"4001_5000": "4001-5000", "5001_8000": "5001-8000", 
							"8001_10000": "8001-10000", "10001_20000": "1万-2万",
							"20001_99999999": "2万以上"}

	var income_family = {"0_2000": "2000以下", "2001_3000": "2001-3000", 
							"3001_5000": "3001-5000", "5001_8000": "5001-8000",
							"8001_10000": "8001-10000","10001_20000":"1万-2万","20001_99999999":"2万以上"}

	//var education_level = ["高中以下","大专/高职","大学本科","硕士","博士及以上"]
	var education_level = ["小学及以下","初中","高中/中专/技校","大专/高职","大学本科","硕士及以上"]
	var major = ["哲学","经济学","法学","教育学","文学","历史学","理学","工学","农学","医学","军事学","管理学"]
	//var industry = ["农林牧渔业", "矿业", "制造业", "电力水力供应", "建筑业", "交通运输", "计算机信息服务", "批发零售业", "住宿餐饮业", "金融业", "房地产业", "科学与技术研究", "公共设施管理", "居民社区服务", "教育", "卫生及社会保障", "文化、体育及娱乐业", "公共管理和社会组织", "国际组织"]
  var industry = ["政府机关/社会团体", "教育科研", "农林牧渔", "矿产能源", "制造业", "建筑/地产", "交通运输/仓储","邮电通讯", "IT行业", "商业/贸易", "旅游/餐饮/酒店", "银行/金融/证券/保险/投资", "媒体/广告/咨询/展览/律师/会计师/商务服务","体育/娱乐", "军人/警察/武警", "健康医疗服务", "其他"]	
	//var position = ['政府工作人员', '企业管理人员', '服务人员/售货员', '自由职业者', '农民', '军人', '失业及下岗人员', '离退休人员', '专业技术人员', '公司职员', '个体经营者', '工人', '教师', '学生', '家庭主妇', '其他']
  var position = ['学生', '党政机关事业单位领导干部', '党政机关事业单位一般职员', '企业/公司管理者', '企业/公司一般职员', '商业服务业职工', '制造生产型企业工人', '个体户/自由职业者', '农村外出务工人员', '农林牧渔劳动者', '退休', '无业/下岗/失业']	
	var seniority = {"0_1":'一年以下', "1_3":'一年到三年', "3_10":'三年到十年', "10_99999999":'十年以上'}

	$.each(income_person, function(name,value){
		// console.log(name+': '+value)
		$('#income_person ul').append('<li name="'+name+'">'+value+'</li>')
	})

	$.each(income_family, function(name,value){
		// console.log(name+': '+value)
		$('#income_family ul').append('<li name="'+name+'">'+value+'</li>')
	})

	$.each(seniority, function(name,value){
		// console.log(name+': '+value)
		$('#seniority ul').append('<li name="'+name+'">'+value+'</li>')
	})

	$.each(education_level, function(index, item){
		// console.log(index+': '+item)
		$('#education_level ul').append('<li name="'+index+'">'+item+'</li>')
	})

	$.each(major, function(index, item){
		// console.log(index+': '+item)
		$('#major ul').append('<li name="'+index+'">'+item+'</li>')
	})

	$.each(industry, function(index, item){
		// console.log(index+': '+item)
		$('#industry ul').append('<li name="'+index+'">'+item+'</li>')
	})

	$.each(position, function(index, item){
		// console.log(index+': '+item)
		$('#position ul').append('<li name="'+index+'">'+item+'</li>')
	})

	// ****************************************************************
	// js load data
	// ****************************************************************

	// gender
	_setupSelector($('#gender'), $('#gender_value').val());

	// birthday
	if ($('#birthday_value').length > 0) {
		if ($('#birthday_value').val() != "-1") {
			// var date_arr = $('#birthday_value').val().split(/\D/);
			// date_arr = $.grep(date_arr, function(value){return value != "";})
			var date_arr = eval($('#birthday_value').val()) || [];
			// console.log(date_arr)
			var date = undefined;
			if(date_arr[0] == date_arr[1]){
				date = new Date(parseInt(date_arr[0])*1000)
				var year = date.getFullYear();
				var month = date.getMonth()+1;
				var day = date.getDate();

				_setupSelector($('#birthday .year'), year+'');
				_setupSelector($('#birthday .month'), month+'');
				_setupSelector($('#birthday .day'), day+'');

				if($.inArray(month, [1,3,5,7,8,10,12]) != -1){
					for (var i = 29; i <= 31; i++) {
						if ($('.select-date .day ul li[name='+i+']').length == 0) {
							$('.select-date .day ul').append('<li name="'+ i +'">'+ i +'</li>');
						};
					};
				}                
				if ($.inArray(month,[4,6,9,11]) != -1){
					if ($('.select-date .day ul li[name=31]').length >= 0) {
						$('.select-date .day ul li[name=31]').remove();
					};
					for (var i = 29; i <= 30; i++) {
						if ($('.select-date .day ul li[name='+i+']').length == 0) {
							$('.select-date .day ul').append('<li name="'+ i +'">'+ i +'</li>');
						};
					};
				}
				if (month == 2){
					for (var i = 29; i <= 31; i++) {
						if ($('.select-date .day ul li[name='+i+']').length >= 0) {
							$('.select-date .day ul li[name='+i+']').remove();
						};
					};
					if((year % 100 == 0 && year % 400 == 0) || (year % 4 == 0)){
						$('.select-date .day ul').append('<li name="29">29</li>');
					}
				}
			}
		}
	};

	// born_address
	_setupAddressSelector($('#born_address'), $('#born_address_value').val());
	// live_address
	_setupAddressSelector($('#live_address'), $('#live_address_value').val());
	// married
	_setupSelector($('#married'), $('#married_value').val());
	// children
	_setupSelector($('#children'), $('#children_value').val());
	// income_person
	_setupCompareSelector($('#income_person'), $('#income_person_value').val(), income_person);
	// income_family
	_setupCompareSelector($('#income_family'), $('#income_family_value').val(), income_family);
	// education
	_setupSelector($('#education_level'), $('#education_level_value').val());
	// major
	_setupSelector($('#major'), $('#major_value').val());
	// industry
	_setupSelector($('#industry'), $('#industry_value').val());
	// position
	_setupSelector($('#position'), $('#position_value').val());
	// seniority
	_setupCompareSelector($('#seniority'), $('#seniority_value').val(), seniority);



	// ********************************
	// AJAX
	// ******************************

	$('.actions').on("click", ".btn.btn-submit:not(.disabled)",function(){
		var b1 = $('#birthday .year .select-txt').attr('name') == '-1';
		var b2 = $('#birthday .month .select-txt').attr('name') == '-1';
		var b3 = $('#birthday .day .select-txt').attr('name') == '-1';
		if (!(b1 == b2 && b2 == b3)){
			$.popupFancybox({cont: "请选择正确的出生日期"})
			return false;
		}

		var nickname = $.trim($('#nickname').val());
		var username = $.trim($('#username').val());
		var gender = $('#gender .select-txt').attr('name');
		var birthday = new Date($('#birthday .year .select-txt').attr('name')+'/'+$('#birthday .month .select-txt').attr('name')+'/'+$('#birthday .day .select-txt').attr('name')).getTime()/1000;
		var born_address = $('#born_address_value').val()
		var live_address = $('#live_address_value').val()
		var married = $('#married .select-txt').attr('name');
		var children = $('#children .select-txt').attr('name');
		var income_person = $('#income_person .select-txt').attr('name');
		var income_family = $('#income_family .select-txt').attr('name');
		var education_level = $('#education_level .select-txt').attr('name');
		var major = $('#major .select-txt').attr('name');
		var industry = $('#industry .select-txt').attr('name');
		var position = $('#position .select-txt').attr('name');
		var seniority = $('#seniority .select-txt').attr('name');

		var _this = $(this);
		_this.addClass('disabled').val("提交中...");

		$.putJSON(
			'/users/setting/update_basic_info',
			{
				attrs: {
					nickname: nickname,
					username: username,
					gender: gender,
					birthday: birthday,
					born_address: born_address,
					live_address: live_address,
					married: married,
					children: children,
					income_person: income_person,
					income_family: income_family,
					education_level: education_level,
					major: major,
					industry: industry,
					position: position,
					seniority: seniority
				}
			}, function(data){
				// console.log(data);
				_this.removeClass('disabled').val("确认提交");
				if (data.success && data.value){
        	if($.util.param('full') === 'false' && $.util.param('ref').length > 0){
        	    var ref = $.util.param('ref');
        	    window.location.href = decodeURIComponent(ref);
        	}else{
        		$.popupFancybox({success: true, cont: "个人资料更新成功！"});
        	}
				}else {
					$.popupFancybox({cont: "操作失败，请保证数据完整！"});
				}
			});
	});

});