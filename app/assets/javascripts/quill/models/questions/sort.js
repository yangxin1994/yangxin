//=require ./base_with_items

/* ================================
 * Model: Sort Question
 * ================================ */

$(function(){
	
	quill.quillClass('quill.models.questions.Sort', quill.models.questions.BaseWithItems, {

		/* Default properties
		 * =========================== */
		_defaults: {
			issue: {
				min: -1,		// min and max is closed interval
				max: -1
			}
		},
		
		_initialize: function() {
			if(this.issue.min < 0 && this.issue.max < 0) {
				this.issue.min = this.issue.max = this.itemCount();
			}
		},

		_newItem: function(model, content) {
			return {
				id: $.util.uid(),
				content: content ? content : $.richtext.defaultValue('新选项')
			}
		},

		_itemCountChanged: function(model) {
			model.setMinMax(model.issue.min, model.issue.max);
		},
		
		setMinMax: function(min, max) {
			if(isNaN(min)) min = 0;
			if(isNaN(max)) max = this.itemCount();
			var count = this.itemCount();
			if(min < 0 && max < 0) {
				min = max = count;
			} else if(min < 0) {
				if(max > count) max = count;
			} else if(max < 0) {
				if(min > count) min = count;
			} else {
				if(min < count) max = min;
				else if(max < count) min = max;
				else min = max = count;
			}
			this.issue.min = min;
			this.issue.max = max;
			this.trigger('change:issue:min_max');
		},

		hasOther: function() {
			return this.issue.other_item && this.issue.other_item.has_other_item;
		},

		_getInfo: function(lang) {
      if(lang=='en') {
        if(this.issue.min <= 0) {
          if(this.issue.max <= 0) return 'Drag to sort';
          else return 'Drag to sort no more than ' + this.issue.max + ' items';
        } else {
          if(this.issue.max <= 0) return 'Drag to sort at least ' + this.issue.min + ' items';
          else if(this.issue.max == this.issue.min) return 'Drag to sort ' + this.issue.min + ' items';
          else return 'Drag to sort ' + this.issue.min + ' to ' + this.issue.max + ' items';
        }
      } else {
        if(this.issue.min <= 0) {
          if(this.issue.max <= 0) return '将右侧选项拖拽至左侧空白处进行排列';
          else return '请最多排出前 ' + this.issue.max + ' 个选项，将右侧选项拖拽至左侧空白处进行排列';
        } else {
          if(this.issue.max <= 0) return '请至少排出前 ' + this.issue.min + ' 个选项，将右侧选项拖拽至左侧空白处进行排列';
          else if(this.issue.max == this.issue.min) return '请排出前 ' + this.issue.min + ' 个选项，将右侧选项拖拽至左侧空白处进行排列';
          else return '请排出前 ' + this.issue.min + ' 到 ' + this.issue.max + ' 个选项，将右侧选项拖拽至左侧空白处进行排列';
        }
      }
		},

		_checkAnswer: function(answer, lang) {
      if(!this.get('is_required')) {
        if(!answer)
          return null;
        if((!answer.sort_result || answer.sort_result.length == 0) && !answer.text_input)
          return null;
      }
      if(lang=='en') {
        if(answer.sort_result == undefined) return 'Please sort the itmes';
        for(var i=0; i<answer.sort_result.length; i++)
          if(answer.sort_result[i] == undefined) return 'Please sort the itmes';
        if(this.issue.min == this.issue.max && this.issue.min > 0 && this.issue.min != answer.sort_result.length) 
          return 'Please sort the first ' + this.issue.min + ' items';
        if(this.issue.min >= 0 && answer.sort_result.length < this.issue.min) return 'Sort at least ' + this.issue.min + ' items';
        if(this.issue.max >= 0 && answer.sort_result.length > this.issue.max) return 'Sort no more than ' + this.issue.max + ' items';
        if(this.hasOther()) {
          for (var i = 0; i < answer.sort_result.length; i++) {
            if(answer.sort_result[i] == this.issue.other_item.id && !answer.text_input) return 'Please fill the content';
          };
        }
        return null;
      } else {
        if(answer.sort_result == undefined) return '请对选项进行排序';
        for(var i=0; i<answer.sort_result.length; i++)
          if(answer.sort_result[i] == undefined) return '请逐名次排序';
        if(this.issue.min == this.issue.max && this.issue.min > 0 && this.issue.min != answer.sort_result.length) 
          return '请排出前 ' + this.issue.min + ' 个选项';
        if(this.issue.min >= 0 && answer.sort_result.length < this.issue.min) return '至少对 ' + this.issue.min + ' 个选项进行排序';
        if(this.issue.max >= 0 && answer.sort_result.length > this.issue.max) return '最多对 ' + this.issue.max + ' 个选项进行排序';
        if(this.hasOther()) {
          for (var i = 0; i < answer.sort_result.length; i++) {
            if(answer.sort_result[i] == this.issue.other_item.id && !answer.text_input) return '请填写其他项内容';
          };
        }
        return null;
      }
		}
		
	});

});