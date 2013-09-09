//=require ../../templates/editors/scale_labels

/* ================================
 * View: Scale question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.Scale', quill.views.editors.BaseWithItems, {
		
		_initialize: function() {
			this.model.on('change:issue:labels', this.refreshLabels, this);
			this.model.on('change:issue:show_unknown', this.refreshUnknown, this);
			this.model.on('change:issue:item_num_per_group', this.refreshItemGroup, this);
		},

		_render: function() {
			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			/* ================================
			 * Editor Right Part
			 * ================================ */

			// show style
			this.addRightBar();
			this.addRightTitle('选项对齐');
			this.addRightItem($.od.odSelector({
				id: this._domId('show_style_slt'),
				values: ['左对齐', '中对齐', '右对齐'],
				index: this.model_issue.show_style,
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setShowStyle(index);
				}, this)
			}));
			this.refreshShowStyle();

			// Item label
			this.addRightBar();
			this.addRightTitle('标签数量');
			this.addRightItem($.od.odSelector({
				id: this._domId('labels_slt'),
				values: ['2 个', '3 个', '4 个', '5 个', '6 个', '7 个'],
				index: this.model_issue.item_num_per_group - 2,
				width: 120,
				onChange: $.proxy(function(index) {
					if(this.model_issue.labels.length == index + 2) 
						return;
					var labels = [];
					switch(index) {
						case 0: labels=['不满意', '满意']; break;
						case 1: labels=['不满意', '一般', '满意']; break;
						case 2: labels=['很不满意', '不满意', '满意', '很满意']; break;
						case 3: labels=['很不满意', '不太满意', '一般', '比较满意', '很满意']; break;
						case 4: labels=['很不满意', '不满意', '不太满意', '比较满意', '满意', '很满意']; break;
						case 5: labels=['很不满意', '不满意', '不太满意', '一般', '比较满意', '满意', '很满意']; break;
					}
					this.model.setLabels(labels);
				}, this)
			}));
			this.refreshLabels();

			this.addRightItem($.od.odCheckbox({
				id: this._domId('unknown_ckb'),
				checked: this.model_issue.show_unknown,
				text: '显示“不清楚”项',
				onChange: $.proxy(function(checked) {
					this.model.setUnknown(checked);
				}, this)
			}));

			// group
			this.addRightBar(true);
			this.addRightTitle('选项分组', true);
			this.addRightItem($.od.odSelector({
				id: this._domId('group_slt'),
				values: ['不分组', '5 项一组', '10 项一组', '15 项一组', '20 项一组', '25 项一组'],
				index: Math.floor(this.model_issue.item_num_per_group / 5),
				width: 120,
				onChange: $.proxy(function(index) {
					this.model.setItemGroup(5 * index);
				}, this)
			}), true);
			// this.addRightBar(true);
			
			// other item
			// this._setupRightOther();
			this.refreshOther();
			
			// 选项乱序
			this._setupRightRandom();
		},

		refreshLabels: function() {
			this._findDom('labels_slt').odSelector('index', this.model_issue.labels.length - 2);

			// labels input
			this.$('.scale-labels').remove();
			this.hbs({
				count: this.model_issue.labels.length,
				labels: this.model_issue.labels
			}, 'scale_labels').appendTo(this.$('.q-body'));
			this.$('.scale-labels input').mouseover(function() {
				$(this).focus().select();
			}).blur($.proxy(function(e) {
				var me = $(e.target);
				this.model.updateLabel(this.$('.scale-labels input').index(me), me.val());
			}, this));
		},

		refreshUnknown: function() {
			this._findDom('unknown_ckb').odCheckbox('val', this.model_issue.show_unknown);
		},

		refreshItemGroup: function() {
			this._findDom('group_slt').odSelector('index', Math.floor(this.model_issue.item_num_per_group / 5));
		},

		refreshShowStyle: function() {
			this._findDom('show_style_slt').odSelector('index', this.model_issue.show_style);
		}
		
	});
	
});