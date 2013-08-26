//=require ./base_with_items

/* ================================
 * Model: Rank Question
 * ================================ */

$(function(){
	
	quill.quillClass('quill.models.questions.Rank', quill.models.questions.BaseWithItems, {

		/* Default properties
		 * =========================== */
		_defaults: {
			issue: {
				show_style: 0,
				icon: 0,
				icon_num: 7,
				bar: 0,
				desc_ary: []
			}
		},
		
		_initialize: function() {
			if(!_.isArray(this.issue.desc_ary))
				this.issue.desc_ary = [];
		},

		_newItem: function(model, content) {
			return {
				id: $.util.uid(),
				content: content ? content : $.richtext.defaultValue('新选项')
			}
		},

		setStyle: function(val) {
			if(this.issue.show_style == val) return;
			this.issue.show_style = val;
			this.trigger('change:issue:show_style');
			this.setLabels(this.issue.desc_ary);		// update labels
		},
		setStyleIcon: function(icon) {
			if(this.issue.icon == icon) return;
			this.issue.icon = icon;
			this.trigger('change:issue:show_style:icon');
		},
		setStyleIconNum: function(icon_num) {
			if(this.issue.icon_num == icon_num) return;
			this.issue.icon_num = icon_num;
			this.trigger('change:issue:show_style:icon_num');
			this.setLabels(this.issue.desc_ary);		// update labels
		},
		setStyleBar: function(bar) {
			if(this.issue.bar == bar) return;
			this.issue.bar = bar;
			this.trigger('change:issue:show_style:bar');
		},

		legalLabelsCount: function() {
			if(this.issue.show_style == 0) {
				var values = [0];
				for (var i = 2; i <= 7 && i <= this.issue.icon_num; i++) {
					if((this.issue.icon_num - i) % (i - 1) == 0)
						values.push(i);
				};
				return values;
			} else {
				return [0, 2, 3, 5, 7];
			}
		},
		setLabels: function(labels) {
			if(!labels) return;
			var legal_counts = this.legalLabelsCount();
			var i = legal_counts.length - 1
			for (; i >= 0; i--) {
				if(legal_counts[i] <= labels.length) break;
			};
			this.issue.desc_ary = _.first(labels, legal_counts[i]);
			this.trigger('change:issue:labels');
		},
		updateLabel: function(index, label) {
			if(index < 0 || index >= this.issue.desc_ary.length) return;
			this.issue.desc_ary[index] = label;
			this.trigger('change:issue:label_update', index, label);
		},
		hasLabel: function() {
			return (this.issue.desc_ary && this.issue.desc_ary.length > 0);
		}
		
	});

});