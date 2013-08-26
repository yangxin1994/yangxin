//=require ../../templates/editors/rank_style
//=require ../../templates/editors/rank_labels

/* ================================
 * View: Rank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.editors.Rank', quill.views.editors.BaseWithItems, {
		
		_initialize: function() {
			this.model.on('change:issue:show_style', this.refreshStyle, this);
			this.model.on('change:issue:show_style:icon', this.refreshStyle, this);
			this.model.on('change:issue:show_style:icon_num', this.refreshStyle, this);
			this.model.on('change:issue:show_style:bar', this.refreshStyle, this);

			this.model.on('change:issue:labels', this.refreshLabels, this);
		},

		_render: function() {
			/* ================================
			 * Editor Left Part
			 * ================================ */
			
			/* ================================
			 * Editor Right Part
			 * ================================ */

			this.addRightBar();
			
			// Item style
			// this.addRightTitle('显示样式');
			
			// this.addRightItem($.od.odSelector({
			// 	id: this._domId('show_style_slt'),
			// 	values: ['图案', '滑竿'],
			// 	index: this.model_issue.show_style,
			// 	width: 120,
			// 	onChange: $.proxy(function(index) {
			// 		this.model.setStyle(index);
			// 	}, this)
			// })).css({marginTop: 0});

			this.addRightItem(this.hbs(this.model_issue, 'rank_style'));
			// icon
			this.$('.style-icon .style-slt:eq(0) .style-slt-items a').click($.proxy(function(e) {
				this.model.setStyleIcon($(e.target).index());
			}, this));
			// icon num
			this.$('.style-icon .style-slt:eq(1) .style-slt-items a').click($.proxy(function(e) {
				this.model.setStyleIconNum($(e.target).index() + 1);
			}, this));
			// bar icon
			this.$('.style-bar .style-slt:eq(0) .style-slt-items a').click($.proxy(function(e) {
				this.model.setStyleBar($(e.target).index());
			}, this));
			this.addRightBar();

			this.refreshStyle();
			
			// Item label
			this.addRightTitle('评分标签', true);
			this.addRightItem($('<div class="labels_slt_con" />'), true);
			this.addRightBar(true);
			this.refreshLabels();
			
			// other item
			this._setupRightOther();
			
			// 选项乱序
			this._setupRightRandom();
		},

		refreshStyle: function() {
			// show style
			this._findDom('show_style_slt').odSelector('val', this.model_issue.show_style);
			if(this.model_issue.show_style == 0) {
				this.$('.style-icon').show();
				this.$('.style-bar').hide();
				// icon
				this.$('.style-icon .style-slt:eq(0) .style-preview').removeClass().addClass(
					'style-preview rank-icon-style-' + this.model_issue.icon);
				this.$('.style-icon .style-slt:eq(0) .style-slt-items a').removeClass('active');
				this.$('.style-icon .style-slt:eq(0) .style-slt-items a.rank-icon-style-' + this.model_issue.icon).addClass('active');
				// icon num
				this.$('.style-icon .style-slt:eq(1) .style-preview').text(this.model_issue.icon_num);
				this.$('.style-icon .style-slt:eq(1) .style-slt-items a').removeClass('active');
				this.$('.style-icon .style-slt:eq(1) .style-slt-items a:eq(' + (this.model_issue.icon_num - 1) + ')').addClass('active');
			} else {
				this.$('.style-icon').hide();
				this.$('.style-bar').show();
				// bar
				this.$('.style-bar .style-slt:eq(0) .style-preview').removeClass().addClass(
					'style-preview rank-bar-style-' + this.model_issue.bar);
				this.$('.style-bar .style-slt:eq(0) .style-slt-items a').removeClass('active');
				this.$('.style-bar .style-slt:eq(0) .style-slt-items a.rank-bar-style-' + this.model_issue.bar).addClass('active');
			}
		},

		refreshLabels: function() {
			this._findDom('labels_slt').odSelector('destroy');

			var legal_counts = this.model.legalLabelsCount();
			var values = [], index = 0;
			for (var i = 0; i < legal_counts.length; i++) {
				if(legal_counts[i] == 0) {
					values.push('无');
				} else {
					values.push(legal_counts[i] + ' 个');
				}
				if(legal_counts[i] == this.model_issue.desc_ary.length) {
					index = i;
				}
			};

			$.od.odSelector({
				id: this._domId('labels_slt'),
				values: values,
				index: index,
				width: 120,
				onChange: $.proxy(function(index) {
					var v = legal_counts[index];
					var labels = this.model_issue.desc_ary;
					if(labels.length == v) return;
					if(labels.length == 0) {
						switch(v) {
							case 0: labels=[]; break;
							case 1: labels=['满意']; break;
							case 2: labels=['不满意', '满意']; break;
							case 3: labels=['不满意', '一般', '满意']; break;
							case 4: labels=['非常不满意', '不满意', '满意', '非常满意']; break;
							case 5: labels=['非常不满意', '不满意', '一般', '满意', '非常满意']; break;
							case 6: labels=['非常不满意', '不满意', '比较不满意', '比较满意', '满意', '非常满意']; break;
							case 7: labels=['非常不满意', '不满意', '比较不满意', '一般', '比较满意', '满意', '非常满意']; break;
						}
					} else {
						if(v < labels.length) {
							labels = _.first(labels, v);
						}
						while(labels.length < v) {
							labels.push('');
						}
					}
					this.model.setLabels(labels);
				}, this)
			}).css('margin', 0).appendTo(this.$('.labels_slt_con'));

			// labels input
			if(this.model_issue.desc_ary.length == 0) {
				this.$('.rank-labels').remove();
			} else {
				this.$('.rank-labels').remove();
				this.hbs(this.model_issue, 'rank_labels').appendTo(this.$('.q-body'));
				this.$('.rank-labels input').mouseover(function() {
					$(this).focus().select();
				}).blur($.proxy(function(e) {
					var me = $(e.target);
					this.model.updateLabel(this.$('.rank-labels input').index(me), me.val());
				}, this));
			}
		}
		
	});
	
});