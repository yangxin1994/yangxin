//=require ../../templates/editors/blank_item
//=require ../../templates/editors/text_blank_min_max
//=require ../../templates/editors/number_blank_min_max
//=require ../../templates/editors/number_blank_unit
//=require ../../templates/editors/time_blank_body_min_max
//=require ui/express_widgets/od_item
//=require ui/express_widgets/od_left_icon_button
//=require ui/express_widgets/od_time_selector

/* ================================
 * View: Blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.Blank', quill.views.editors.Base, {
		
		_initialize: function() {
			this.model.on('change:items:add', this.addItem, this);
			this.model.on('change:items:update', this.updateItem, this);
			this.model.on('change:items:remove', this.removeItem, this);
			this.model.on('change:items:move', this.moveItem, this);

			this.model.on('change:items:data_type', this.refreshItemDetail, this);

			this.model.on('change:issue:random', this.refreshRandom, this);
			this.model.on('change:issue:show_style', this.refreshStyle, this);

			// text
			this.model.on('change:text:min_max', this.refreshTextMinMax, this);
			this.model.on('change:text:multiple', this.refreshTextMultiple, this);
			this.model.on('change:text:size', this.refreshTextSize, this);
			// number
			this.model.on('change:number:min_max', this.refreshNumberMinMax, this);
			this.model.on('change:number:unit', this.refreshNumberUnit, this);
			this.model.on('change:number:unit_location', this.refreshNumberUnitLocation, this);
			this.model.on('change:number:precision', this.refreshNumberPrecision, this);
			// phone
			this.model.on('change:phone:phone_type', this.refreshPhoneType, this);
			// time
			this.model.on('change:time:format', this.refreshTimeFormat, this);
			this.model.on('change:time:format', this.refreshTimeMinMax, this);
			this.model.on('change:time:min_max', this.refreshTimeMinMax, this);
			// address
			this.model.on('change:address:has_postcode', this.refreshAddressPostcode, this);
			this.model.on('change:address:format', this.refreshAddressFormat, this);
		},

		_render: function() {
			
			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			// items
			$('<div class="q-items" />').appendTo(this.$('.q-body')).sortable({
				stop: $.proxy(function(event, ui) {
					this.model.moveItem(ui.item.data('id'), ui.item.index());
				}, this)
			}).disableSelection();
			$.each(this.model.getItems(), $.proxy(function(i, v) {
				this._renderItem(v.id, this.model);
			}, this));

			// add new item
			$.od.odLeftIconButton({
				text: '添加子题目',
				width: 90
			}).appendTo($('<div class="q-new-opt" />').appendTo(this.$('.q-body'))).click($.proxy(function() {
				this.model.addItem();
			}, this));

			$('<div style="height:100px" />').appendTo(this.$('.q-body'));

			/* ================================
			 * Editor Right Part
			 * ================================ */

			// style
			this.addRightBar();
			this.addRightTitle('显示样式');
			this.addRightItem($.od.odSelector({
				id: this._domId('style_slt'),
				values: ['子标题居上', '右对齐', '中对其', '左对齐'],
				index: this.model_issue.show_style,
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setStyle(index);
				}, this)
			}));
			this.refreshStyle();

			// random
			this.addRightItem($.od.odCheckbox({
				id: this._domId('rand_ckb'),
				checked: false,
				text: '子题目乱序',
				onChange: $.proxy(function(checked) {
					this.model.setRandom(checked);
				}, this)
			}));
			this.refreshRandom();
		},

		/* Items related
		 * ========================= */
		_renderItem: function(id, handler) {
			// render a new item and add it to the
			var item = handler.findItem(id);
			if(!item) return;

			var con = this.hbs(this._domId(id), 'blank_item').data('id', id).appendTo(this.$('.q-items'));
			
			// option
			var opt = $.od.odItem({
				width: 575,
				value: item.content
			}).appendTo($('.item-opt', con));
			con.data('option', opt);
			
			var ript = opt.odItem('richInput');
			ript.odRichInput('innerInput').blur($.proxy(function() {
				handler.updateItem(id, ript.odRichInput('val'));
			}, this));
			
			opt.odItem('getRemoveBtn').click($.proxy(function() {
				handler.removeItem(id);
			}, this));

			// detail
			this.refreshItemDetail(id);

			return con;
		},
		addItem: function(id, handler) {
			var con = this._renderItem(id, handler);
			if(con.is(':visible'))
				con.data('option').odItem('richInput').odRichInput('innerInput').focus();
		},
		updateItem: function(id, handler) {
			var item = handler.findItem(id);
			if(!item) return;
			this._findDom(id).data('option').odItem('richInput').odRichInput('val', item.content);
		},
		removeItem: function(id, handler) {
			var con = this._findDom(id);
			con.data('option').odItem('destroy');
			con.remove();
		},
		moveItem: function(id, target_index, handler) {
			var con = this._findDom(id);
			if(!con || con.index() == target_index) return;
			con.detach();
			if(target_index == handler.getItems().length - 1) {
				con.appendTo(this.$('.q-items'));
			} else {
				con.insertBefore(this.$('blank-item:eq(' + target_index + ')'));
			}
		},

		/* Refresh item's detail editor
		 * ========================= */
		refreshItemDetail: function(id) {
			var item = this.model.findItem(id);
			if(!item) return;
			var con = $('.item-detail', this._findDom(id));
			if(con.length == 0) return;

			// 1. type selector
			var type_con = $('.detail-column:eq(0)', con).empty();
			$('<h1>类型</h1>').appendTo(type_con);
			$.od.odSelector({
				id: this._domId(id + '_data_type'),
				values: quill.helpers.BlankType.getLabels(),
				index: quill.helpers.BlankType.getValue(item.data_type),
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setDataType(id, quill.helpers.BlankType.getName(index));
				}, this)
			}).appendTo(type_con);

			// 2. detail
			$('.detail-column:gt(0)', con).empty();
			var handler = this.model.loadHandler(id);
			var _refresh = {};

			// Refresh text input
			_refresh['Text'] = $.proxy(function() {
				// min max
				var min_max_dom = $('.detail-column:eq(1)', con).empty();
				$('<h1>字数限制</h1>').appendTo(min_max_dom);
				$.od.odSelector({
					id: this._domId(id + '_min_max_slt'),
					values: ['不限制', '设下限', '设上限', '自定义'],
					index: handler.getMinMaxType(),
					width: 120,
					onChange: $.proxy(function(index) {
						var min = -1, max = -1;
						switch(index) {
							case 0: break;
							case 1: min = (handler.target.min_length < 0 ? 5 : handler.target.min_length); break;
							case 2: max = (handler.target.max_length < 0 ? 100 : handler.target.max_length); break;
							case 3: 
								min = (handler.target.min_length < 0 ? 5 : handler.target.min_length); 
								max = (handler.target.max_length < 0 ? 100 : handler.target.max_length);
								break;
						}
						handler.setMinMax(min, max);
					}, this)
				}).appendTo(min_max_dom);

				this.hbs(null, 'text_blank_min_max').appendTo(min_max_dom);
				$('.min-max input', min_max_dom).numeric({ decimal: false, negative: false }, function() {
					$(this).focus();
				});
				$('.min-max input', min_max_dom).each($.proxy(function(i, ipt) {
					var $ipt = $(ipt);
					$ipt.blur($.proxy(function(e) {
						var min = -1, max = -1;
						var $p = $ipt.parent();
						switch($p.index()) {
							case 0: min = parseInt($('input', $p).val()); break;
							case 1: max = parseInt($('input', $p).val()); break;
							case 2: min = parseInt($('input:eq(0)', $p).val()); max = parseInt($('input:eq(1)', $p).val()); break;
						}
						handler.setMinMax(min, max);
					}, this));
				}, this));
				
				this.refreshTextMinMax(handler);

				// size and multiple
				var size_dom = $('.detail-column:eq(2)', con).empty();
				$('<h1>输入框尺寸</h1>').appendTo(size_dom);
				
				$.od.odSelector({
					id: this._domId(id + '_multiple_slt'),
					values: ['单行', '多行'],
					index: handler.target.has_multiple_line ? 1 : 0,
					width: 120,
					onChange: $.proxy(function(index) {
						handler.setMultiple(index == 1);
					}, this)
				}).appendTo(size_dom);
				this.refreshTextMultiple(handler);

				$('<div style="height:5px;" />').appendTo(size_dom);
				$.od.odSelector({
					id: this._domId(id + '_size_slt'),
					values: ['小', '中', '大'],
					index: handler.target.size,
					width: 120,
					onChange: $.proxy(function(index) {
						handler.setSize(index);
					}, this)
				}).appendTo(size_dom);
				this.refreshTextSize(handler);
			}, this);
			
			// Refresh number input
			_refresh['Number'] = $.proxy(function() {
				// precision
				var precision_dom = $('.detail-column:eq(1)', con).empty();
				$('<h1>数值精度</h1>').appendTo(precision_dom);
				
				$.od.odSelector({
					id: this._domId(id + '_precision_slt'),
					values: ['整数', '小数（0.0）', '0.00', '0.000', '0.0000'],
					index: handler.target.precision,
					width: 120,
					onChange: $.proxy(function(index) {
						handler.setPrecision(index);
					}, this)
				}).appendTo(precision_dom);
				this.refreshNumberPrecision(handler);
				
				// min max
				var min_max_dom = $('.detail-column:eq(2)', con).empty();
				$('<h1>数值范围</h1>').appendTo(min_max_dom);
				
				$.od.odSelector({
					id: this._domId(id + '_min_max_slt'),
					values: ['不限制', '设下限', '设上限', '自定义'],
					index: handler.getMinMaxType(),
					width: 120,
					onChange: $.proxy(function(index) {
						var min = handler.MIN_INT, max = handler.MAX_INT;
						switch(index) {
							case 0: break;
							case 1: min = (handler.target.min_value == handler.MIN_INT ? 0 : handler.target.min_value); break;
							case 2: max = (handler.target.max_value == handler.MAX_INT ? 100 : handler.target.max_value); break;
							case 3: 
								min = (handler.target.min_value == handler.MIN_INT ? 0 : handler.target.min_value); 
								max = (handler.target.max_value == handler.MAX_INT ? 100 : handler.target.max_value);
								break;
						}
						handler.setMinMax(min, max);
					}, this)
				}).appendTo(min_max_dom);

				this.hbs(null, 'number_blank_min_max').appendTo(min_max_dom);
				$('.number-blank-min-max input', min_max_dom).numeric({}, function() {
					$(this).focus();
				});
				$('.number-blank-min-max input', min_max_dom).each($.proxy(function(i, ipt) {
					var $ipt = $(ipt);
					$ipt.blur($.proxy(function(e) {
						var min = handler.MIN_INT, max = handler.MAX_INT;
						var $p = $ipt.parent();
						switch($p.index()) {
							case 0: min = parseInt($('input', $p).val()); break;
							case 1: max = parseInt($('input', $p).val()); break;
							case 2: min = parseInt($('input:eq(0)', $p).val()); max = parseInt($('input:eq(1)', $p).val()); break;
						}
						handler.setMinMax(min, max);
					}, this));
				}, this));
				
				this.refreshNumberMinMax(handler);

				// unit
				var unit_dom = $('.detail-column:eq(3)', con).empty();
				$('<h1>设置单位</h1>').appendTo(unit_dom);
				
				$.od.odSelector({
					id: this._domId(id + '_unit_slt'),
					values: ['无单位', '单位后置', '单位前置'],
					index: handler.target.unit_location,
					width: 120,
					onChange: $.proxy(function(index) {
						handler.setUnitLocation(index);
					}, this)
				}).appendTo(unit_dom);

				this.hbs(handler.target, 'number_blank_unit').appendTo(unit_dom);
				$('.number-blank-unit-edit input', unit_dom).blur($.proxy(function(e) {
					handler.setUnit($.trim($(e.target).val()));
				}, this));
				
				this.refreshNumberUnitLocation(handler);
				this.refreshNumberUnit(handler);
			}, this);

			// Refresh email input
			_refresh['Email'] = $.proxy(function() {}, this);

			// Refresh url input
			_refresh['Url'] = $.proxy(function() {}, this);

			// Refresh phone input
			_refresh['Phone'] = $.proxy(function() {
				// phone type
				var type_dom = $('.detail-column:eq(1)', con).empty();
				$('<h1>电话类型</h1>').appendTo(type_dom);
				$.od.odSelector({
					id: this._domId(id + '_phone_type_slt'),
					values: ['座机', '手机', '座机或手机'],
					index: handler.getPhoneType(),
					width: 120,
					onChange: $.proxy(function(index) {
						handler.setPhoneType(index);
					}, this)
				}).appendTo(type_dom);
				this.refreshPhoneType(handler);
			}, this);

			// Refresh time input
			_refresh['Time'] = $.proxy(function() {
				// scope selector
				this.hbs(null, 'time_blank_body_min_max').appendTo(con);

				// format
				var format_dom = $('.detail-column:eq(1)', con).empty();
				$('<h1>时间格式</h1>').appendTo(format_dom);
				$.od.odSelector({
					id: this._domId(id + '_format_slt'),
					values: ['年', '年月', '年月日', '年月日/时分', '月日', '时分', '时分秒'],
					index: handler.target.format,
					width: 120,
					onChange: $.proxy(function(index) {
						handler.setFormat(index);
					}, this)
				}).appendTo(format_dom);
				this.refreshTimeFormat(handler);

				// min max
				var min_max_dom = $('.detail-column:eq(2)', con).empty();
				$('<h1>可选时间范围</h1>').appendTo(min_max_dom);
				$.od.odSelector({
					id: this._domId(id + '_min_max_slt'),
					values: ['不限制', '设置截止时间', '设置起始时间', '自定义时间段'],
					index: handler.getMinMaxType(),
					width: 120,
					onChange: $.proxy(function(index) {
						var min = $.util.MIN_TIME, max = $.util.MAX_TIME;
						var time = (new Date()).getTime();
						switch(index) {
							case 0: break;
							case 1: max = (handler.target.max == $.util.MAX_TIME ? time : handler.target.max); break;
							case 2: min = (handler.target.min == $.util.MIN_TIME ? time : handler.target.min); break;
							case 3: 
								min = (handler.target.min == $.util.MIN_TIME ? time : handler.target.min); 
								max = (handler.target.max == $.util.MAX_TIME ? time : handler.target.max);
								break;
						}
						handler.setMinMax(min, max);
					}, this)
				}).appendTo(min_max_dom);
				this.refreshTimeMinMax(handler);

			}, this);

			// Refresh address input
			_refresh['Address'] = $.proxy(function() {
				// format
				var format_dom = $('.detail-column:eq(1)', con).empty();
				$('<h1>地址精确到</h1>').appendTo(format_dom);
				
				$.od.odSelector({
					id: this._domId(id + '_format_slt'),
					values: ['省', '市', '区（县）', '详细地址'],
					index: handler.getFormat(),
					width: 120,
					onChange: $.proxy(function(index) {
						handler.setFormat(index);
					}, this)
				}).appendTo(format_dom);
				this.refreshAddressFormat(handler);

				// postcode
				var postcode_dom = $('.detail-column:eq(2)', con).empty();
				$('<h1>&nbsp;</h1>').appendTo(postcode_dom);
				$.od.odCheckbox({
					id: this._domId(item.id + '_postcode_ckb'), 
					checked: handler.target.has_postcode,
					text: '包含邮编',
					onChange: $.proxy(function(checked) {
						handler.setPostcode(checked);
					}, this)
				}).appendTo(postcode_dom).css('marginTop', '4px');
				this.refreshAddressPostcode(handler);
			}, this);
			
			_refresh[item.data_type]();
		},

		/* Text input
		 * ========================= */
		refreshTextMinMax: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			var con = this._findDom(item.id);

			var type = handler.getMinMaxType();
			this._findDom(item.id + '_min_max_slt').odSelector('index', type);

			$('.min-max > div', con).hide();
			switch(type) {
				case 0: break;
				case 1: $('.min-max > div:eq(0) input', con).val(handler.target.min_length); break;
				case 2: $('.min-max > div:eq(1) input', con).val(handler.target.max_length); break;
				case 3: 
					$('.min-max > div:eq(2) input:eq(0)', con).val(handler.target.min_length);
					$('.min-max > div:eq(2) input:eq(1)', con).val(handler.target.max_length);
					break;
			}
			if(type > 0) {
				$('.min-max > div:eq(' + (type - 1) + ')', con).show();
			}
		},
		refreshTextMultiple: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			this._findDom(item.id + '_size_slt').odSelector('index', handler.target.size);
		},
		refreshTextSize: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			this._findDom(item.id + '_multiple_slt').odSelector('index', handler.target.has_multiple_line ? 1 : 0);
		},

		/* Number input
		 * ========================= */
		refreshNumberPrecision: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			this._findDom(item.id + '_precision_slt').odSelector('index', handler.target.precision);
		},
		refreshNumberMinMax: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			var con = this._findDom(item.id);

			var type = handler.getMinMaxType();
			this._findDom(item.id + '_min_max_slt').odSelector('index', type);
			$('.number-blank-min-max > div', con).hide();
			switch(type) {
				case 0: break;
				case 1: $('.number-blank-min-max > div:eq(0) input', con).val(handler.target.min_value); break;
				case 2: $('.number-blank-min-max > div:eq(1) input', con).val(handler.target.max_value); break;
				case 3: 
					$('.number-blank-min-max > div:eq(2) input:eq(0)', con).val(handler.target.min_value);
					$('.number-blank-min-max > div:eq(2) input:eq(1)', con).val(handler.target.max_value);
					break;
			}
			if(type > 0) {
				$('.number-blank-min-max > div:eq(' + (type - 1) + ')', con).show();
			}
		}, 
		refreshNumberUnitLocation: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			var con = this._findDom(item.id);

			this._findDom(item.id + '_unit_slt').odSelector('index', handler.target.unit_location);
			if(handler.target.unit_location > 0) {
				$('.number-blank-unit-edit', con).show();
			} else {
				$('.number-blank-unit-edit', con).hide();
			}
		},
		refreshNumberUnit: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			var con = this._findDom(item.id);
			$('.number-blank-unit-edit input', con).val(handler.target.unit);
		},
		
		/* Phone input
		 * ========================= */
		refreshPhoneType: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			this._findDom(item.id + '_phone_type_slt').odSelector('index', handler.getPhoneType());
		},

		/* Time input
		 * ========================= */
		refreshTimeFormat: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			this._findDom(item.id + '_format_slt').odSelector('index', handler.target.format);
		}, 
		refreshTimeMinMax: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			var con = this._findDom(item.id);

			this._findDom(item.id + '_min_max_slt').odSelector('index', handler.getMinMaxType());

			this._findDom(item.id + '_min_time_slt').odTimeSelector('destroy');
			this._findDom(item.id + '_max_time_slt').odTimeSelector('destroy');

			$.od.odTimeSelector({
				id: this._domId(item.id + '_min_time_slt'),
				format: handler.target.format,
				value: handler.target.min,
				onChange: $.proxy(function(value) {
					switch(handler.getMinMaxType()) {
						case 2: case 3: handler.setMinMax(value, handler.target.max); break;
					}
				}, this)
			}).appendTo($('.time-blank-slt:eq(0) > div', con));

			$.od.odTimeSelector({
				id: this._domId(item.id + '_max_time_slt'),
				format: handler.target.format,
				value: handler.target.max,
				onChange: $.proxy(function(value) {
					switch(handler.getMinMaxType()) {
						case 1: case 3: handler.setMinMax(handler.target.min, value); break;
					}
				}, this)
			}).appendTo($('.time-blank-slt:eq(1) > div', con));

			$('.time-blank-slt', con).hide();
			switch(handler.getMinMaxType()) {
				case 1: $('.time-blank-slt:eq(1)', con).show(); break;
				case 2: $('.time-blank-slt:eq(0)', con).show(); break;
				case 3: $('.time-blank-slt', con).show(); break;
			}
		},

		/* Address
		 * ========================= */
		refreshAddressFormat: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			this._findDom(item.id + '_format_slt').odSelector('index', handler.getFormat());
		}, 
		refreshAddressPostcode: function(handler) {
			var item = this.model.getHandlerItem(handler);
			if(!item) return;
			this._findDom(item.id + '_postcode_ckb').odCheckbox('val', handler.target.has_postcode);
		},

		/* Refresh random
		 * ========================= */
		refreshRandom: function() {
			this._findDom('rand_ckb').odCheckbox('val', this.model_issue.is_rand);
		},

		/* Refresh style
		 * ========================= */
		refreshStyle: function() {
			this._findDom('style_slt').odSelector('index', this.model_issue.show_style);
		}

	});
	
});