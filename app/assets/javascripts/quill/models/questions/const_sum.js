//=require ./base_with_items

/* ================================
 * Model: Const sum Question
 * ================================ */

$(function(){
	
	quill.quillClass('quill.models.questions.ConstSum', quill.models.questions.BaseWithItems, {

		/* Default properties
		 * =========================== */
		_defaults: {
			issue: {
				show_style: 0,
				sum: 100
			}
		},
		
		_initialize: function() { },

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
		},

		setSum: function(sum) {
			if(isNaN(sum)) sum = 100;
			if(this.issue.sum == sum) return;
			if(sum <= 0) sum = 100;
			this.issue.sum = sum;
			this.trigger('change:issue:sum');
		},

		_getInfo: function(lang) {
			return (lang=='en' ? 'Total is ' : '请为每个选项配额，总和为') + this.issue.sum;
		},

		_checkAnswer: function(answer, lang) {
      if(!this.get('is_required')) {
        if(!answer)
          return null;
        if(_.keys(answer).length == 0)
          return null;
      }
			var sum = 0;
			for (var i = 0; i < this.issue.items.length; i++) {
				var id = this.issue.items[i].id;
				if(isNaN(answer[id]))
					return lang=='en' ? 'Please fill every option' : '请为所有选项进行配额';
				sum += answer[id];
			};
			if(this.issue.other_item && this.issue.other_item.has_other_item) {
				var a = answer[this.issue.other_item.id]
				if(a != undefined) {
					if(a != 0 && !answer.text_input) return lang=='en' ? 'Please input content' : '请填写其他项内容';
					sum += answer[this.issue.other_item.id];
				}
			}
			if(this.issue.sum != sum) return (lang=='en' ? 'Total should be ' : '输入总额需要为 ') + this.issue.sum;
			return null;
		}

	});

});