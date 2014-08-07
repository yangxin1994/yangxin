//=require ./base_with_items

/* ================================
 * Model: Choice Question
 * ================================ */

$(function(){

	quill.quillClass('quill.models.questions.Choice', quill.models.questions.BaseWithItems, {

		/* Properties of choice issue
		 * =========================== */
		_defaults: {
			issue: {
				choice_num_per_row: 1,
				option_type: 0,
				min_choice: 1,
				max_choice: 2
			}
		},
		
		_initialize: function() {
			if(this.issue.choice_num_per_row <= 0)
				this.issue.choice_num_per_row = 1;
		},

		_newItem: function(model, content) {
			return {
				id: $.util.uid(),
				content: content ? content : $.richtext.defaultValue('新选项'),
				is_exclusive: false
			};
		},

		_itemCountChanged: function(model) {
			model.setMinMax(model.issue.min_choice, model.issue.max_choice);
		},

		/* item type
		 * ===================== */
		setItemType: function(type) {
			this.issue.option_type = type;
			switch(type) {
				case 0: this.setMinMax(1, 1); break;
				case 1: this.setMinMax(1, 1); break;
				case 2: this.setMinMax(0, 100); break;
				case 3: this.setMinMax(this.issue.min_choice, this.issue.min_choice); break;
				case 4: this.setMinMax(0, this.issue.max_choice); break;
				case 5: this.setMinMax(this.issue.min_choice, 100); break;
				case 6: this.setMinMax(this.issue.min_choice, this.issue.max_choice); break;
			}
			this.trigger('change:issue:option_type');
		},
		setMinMax: function(min, max) {
			if(isNaN(min)) min = 0;
			if(isNaN(max)) max = this.itemCount();
			var count = this.itemCount();
			switch(this.issue.option_type) {
				case 0: min = 1; max = 1; break;
				case 1: min = 1; max = 1; break;
				case 2: min = 0; max = 100; break;
				case 3: if(min > count) min = count; max = min; break;
				case 4: min = 0; if(max > count) max = count; break;
				case 5: if(min > count) min = count; max = 100; break;
				case 6: if(max > count) max = count; if(min > max) min = max; break;
			}
			this.issue.min_choice = min;
			this.issue.max_choice = max;
			this.trigger('change:issue:min_max');
		},
		
		/* Column count
		 * ============================ */
		setColumnCount: function(column) {
			this.issue.choice_num_per_row = column;
			this.trigger('change:issue:column');
		},
		
		/* Item exclude
		 * ============================ */
		hasExclusive: function() {
			var other_item = this.getOther();
			var retval = other_item.has_other_item ? other_item.is_exclusive : false;
			return retval || _.reduce(this.getItems(), function(memo, item){ 
				return memo || item.is_exclusive; 
			}, false);
		},
		setExclusive: function(index, is_exclusive) {
			var items = this.getItems();
			if(index < 0 || index > items.length) return;
			if(index == items.length) {
				// other item
				this.getOther().is_exclusive = is_exclusive;
			} else {
				items[index].is_exclusive = is_exclusive;
			}
			this.trigger('change:issue:exclusive');
		},
		
		_getInfo: function(lang) {
      if(lang=='en') {
        switch(this.issue.option_type) {
          case 0: case 1: return 'Single Choice';
          case 2: return 'Multiple Choice';
          case 3: return 'Choose ' + this.issue.min_choice + ' options';
          case 4: return 'Choose no more than ' + this.issue.max_choice + ' options';
          case 5: return 'Choose at least ' + this.issue.min_choice + ' options';
          case 6: return 'Choose ' + this.issue.min_choice + ' to ' + this.issue.max_choice + ' options';
        }
        return null;
      } else {
        switch(this.issue.option_type) {
          case 0: case 1: return '单选题';
          case 2: return '多选题';
          case 3: return '请选择 ' + this.issue.min_choice + ' 项';
          case 4: return '最多选择 ' + this.issue.max_choice + ' 项';
          case 5: return '至少选择 ' + this.issue.min_choice + ' 项';
          case 6: return '请选择 ' + this.issue.min_choice + ' 到 ' + this.issue.max_choice + ' 项';
        }
        return null;
      }
		},

		_checkAnswer: function(answer, lang) {
      if(lang=='en') {
        if(!answer.selection) return  'Answer should not be empty';
        switch(this.issue.option_type) {
          // TODO: If survey editor remove an item (whose id is in answer.selection) after the answer is created,
          // using answer.selection.length to check answer will be incorrect.
          // MatrixChoice has the same problem
          case 0: case 1: case 3:
            if(answer.selection.length != this.issue.min_choice) return 'Please choose ' + this.issue.min_choice + ' options';
            break;
          default:
            if(answer.selection.length < this.issue.min_choice) return 'Choose at least ' + this.issue.min_choice + ' options';
            if(answer.selection.length > this.issue.max_choice) return 'Choose no more than ' + this.issue.max_choice + ' options';
            break;
        }
        if(this.issue.other_item && this.issue.other_item.has_other_item) {
          if(_.contains(answer.selection, this.issue.other_item.id)) {
            if(!answer.text_input) return 'Please input content';
          }
        }
        return null;
      } else {
        if(!answer.selection) return '答案不能为空';
        switch(this.issue.option_type) {
          // TODO: If survey editor remove an item (whose id is in answer.selection) after the answer is created,
          // using answer.selection.length to check answer will be incorrect.
          // MatrixChoice has the same problem
          case 0: case 1: case 3:
            if(answer.selection.length != this.issue.min_choice) return '请选择 ' + this.issue.min_choice + ' 项';
            break;
          default:
            if(answer.selection.length < this.issue.min_choice) return '至少选择 ' + this.issue.min_choice + ' 项';
            if(answer.selection.length > this.issue.max_choice) return '最多选择 ' + this.issue.max_choice + ' 项';
            break;
        }
        if(this.issue.other_item && this.issue.other_item.has_other_item) {
          if(_.contains(answer.selection, this.issue.other_item.id)) {
            if(!answer.text_input) return '请填写内容';
          }
        }
        return null;
      }
		}

	});

});