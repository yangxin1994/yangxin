//=require ../../templates/editors/time_blank_body
//=require ../../templates/editors/time_blank_body_min_max
//=require ui/express_widgets/od_time_selector

/* ================================
 * View: Time blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.TimeBlank', quill.views.editors.Base, {
		
		_initialize: function() {
			this.model.on('change:time:format', this.refreshFormat, this);
			this.model.on('change:time:format', this.refreshMinMax, this);
			this.model.on('change:time:min_max', this.refreshMinMax, this);
		},

		_render: function() {
			
			this.$('.editor-method').hide();	// hide toggle between code and visual

			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			// input preview
			this.hbs(null, 'time_blank_body').appendTo(this.$('.q-body'));
			this.hbs(null, 'time_blank_body_min_max').appendTo(this.$('.q-body'));

			/* ================================
			 * Editor Right Part
			 * ================================ */
			
			// format
			this.addRightBar();
			this.addRightTitle('时间格式');
			this.addRightItem($.od.odSelector({
				id: this._domId('format_slt'),
				values: ['年', '年月', '年月日', '年月日/时分', '月日', '时分', '时分秒'],
				index: this.model_issue.format,
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setFormat(index);
				}, this)
			}));
			this.refreshFormat();

			// min max
			this.addRightBar(true);
			this.addRightTitle('可选时间范围', true);
			this.addRightItem($.od.odSelector({
				id: this._domId('min_max_slt'),
				values: ['不限制', '设置截止时间', '设置起始时间', '自定义时间段'],
				index: this.model.getMinMaxType(),
				width: 120,
				onChange: $.proxy(function(index) {
					var min = $.util.MIN_TIME, max = $.util.MAX_TIME;
					var time = (new Date()).getTime();
					switch(index) {
						case 0: break;
						case 1: max = (this.model_issue.max == $.util.MAX_TIME ? time : this.model_issue.max); break;
						case 2: min = (this.model_issue.min == $.util.MIN_TIME ? time : this.model_issue.min); break;
						case 3: 
							min = (this.model_issue.min == $.util.MIN_TIME ? time : this.model_issue.min); 
							max = (this.model_issue.max == $.util.MAX_TIME ? time : this.model_issue.max);
							break;
					}
					this.model.setMinMax(min, max);
				}, this)
			}), true);
			this.refreshMinMax();
		},

		refreshFormat: function() {
			this._findDom('format_slt').odSelector('index', this.model_issue.format);
			this.$('.ipt-preview li').hide();
			var _show = $.proxy(function(from, to) {
				for (var i = from; i < to; i++) {
					this.$('.ipt-preview li:eq(' + i + ')').show();
				};
			}, this);
			switch(this.model_issue.format) {
				case 0: case 1: case 2: _show(0, this.model_issue.format + 1); break;
				case 3: _show(0, 5); break;
				case 4: _show(1, 3); break;
				case 5: _show(3, 5); break;
				case 6: _show(3, 6); break;
			}
		}, 

		refreshMinMax: function() {
			this._findDom('min_max_slt').odSelector('index', this.model.getMinMaxType());

			this._findDom('min_time_slt').odTimeSelector('destroy');
			this._findDom('max_time_slt').odTimeSelector('destroy');

			$.od.odTimeSelector({
				id: this._domId('min_time_slt'),
				format: this.model_issue.format,
				value: this.model_issue.min,
				onChange: $.proxy(function(value) {
					switch(this.model.getMinMaxType()) {
						case 2: case 3: this.model.setMinMax(value, this.model_issue.max); break;
					}
				}, this)
			}).appendTo(this.$('.time-blank-slt:eq(0) > div'));

			$.od.odTimeSelector({
				id: this._domId('max_time_slt'),
				format: this.model_issue.format,
				value: this.model_issue.max,
				onChange: $.proxy(function(value) {
					switch(this.model.getMinMaxType()) {
						case 1: case 3: this.model.setMinMax(this.model_issue.min, value); break;
					}
				}, this)
			}).appendTo(this.$('.time-blank-slt:eq(1) > div'));

			this.$('.time-blank-slt').hide();
			switch(this.model.getMinMaxType()) {
				case 1: this.$('.time-blank-slt:eq(1)').show(); break;
				case 2: this.$('.time-blank-slt:eq(0)').show(); break;
				case 3: this.$('.time-blank-slt').show(); break;
			}

		}
		
	});
	
});