//=require ./base_with_items

/* ================================
 * Model: Scale Question
 * ================================ */

$(function(){
	
	quill.quillClass('quill.models.questions.Scale', quill.models.questions.BaseWithItems, {

		/* Default properties
		 * =========================== */
		_defaults: {
			issue: {
				//NOTE: other_item is not used in scale question!
				item_num_per_group: -1,
				labels: ['很不满意', '不太满意', '一般', '比较满意', '很不意'],
				show_unknown: false,
				show_style: 2	// 整型，可以是0（左对齐），1（居中），2（右对齐）
			}
		},
		
		_initialize: function() { },

		_newItem: function(model, content) {
			return {
				id: $.util.uid(),
				content: content ? content : $.richtext.defaultValue('新选项')
			}
		},

		setItemGroup: function(num_per_group) {
			if(this.issue.item_num_per_group == num_per_group) return;
			this.issue.item_num_per_group = num_per_group;
			this.trigger('change:issue:item_num_per_group');
		},

		setUnknown: function(show) {
			if(this.issue.show_unknown == show) return;
			this.issue.show_unknown = show;
			this.trigger('change:issue:show_unknown');
		},

		setLabels: function(labels) {
			this.issue.labels = labels;
			this.trigger('change:issue:labels');
		},
		updateLabel: function(index, label) {
			if(index < 0 || index >= this.issue.labels.length) return;
			this.issue.labels[index] = label;
			this.trigger('change:issue:label_update', index, label);
		},

		setShowStyle: function(style) {
			this.issue.show_style = style;
			this.trigger('change:issue:show_style');
		},
		
		_getInfo: function(lang) {
			return null;
		},

		_checkAnswer: function(answer, lang) {
			for (var i = 0; i < this.issue.items.length; i++) {
				var item = this.issue.items[i];
				if(answer[item.id] == undefined)
					return lang=='en' ? 'Rank for all items' : '请为所有项评分';
				if(answer[item.id] >= this.issue.labels.length)
					return lang=='en' ? 'error' : '评分有误，请重新评分';
			};
			return null;
		}
		
	});

});