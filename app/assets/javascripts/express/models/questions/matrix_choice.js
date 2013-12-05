/* ================================
 * Model: Matrix Chocie Question
 * ================================ */

$(function(){
	
	quill.quillClass('quill.models.questions.MatrixChoice', quill.models.questions.Base, {

		/* Default properties
		 * =========================== */
		_defaults: {
			issue: {
				// choices
				option_type: 0,
				min_choice: 1,
				max_choice: 2,

				// sub questions
				is_row_rand: false,
				show_style: 2, 	//整型，可以是0（左对齐），1（居中对齐），或者2（右对齐）
				row_num_per_group: 0
			}
		},

		itemsHandler: null,

		rowsHandler: null,
		
		_initialize: function() {
			// choices
			this.itemsHandler = quill.modules.items(this, 'item', false, this._newItem, this._itemCountChanged);

			// sub questions
			this.rowsHandler = quill.modules.items(this, 'row', false, this._newRow);

			$.extend(this, quill.modules.rand(this, this.issue));
			
			if(this.issue.row_num_per_group < 0)
				this.issue.row_num_per_group = 0;
		},

		/* =========================== *
		 * Handle choices
		 * =========================== */
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

		/* Item exclude
		 * ============================ */
		hasExclusive: function() {
			return _.reduce(this.issue.items, function(memo, item){ 
				return memo || item.is_exclusive; 
			}, false);
		},
		setExclusive: function(index, is_exclusive) {
			if(index < 0 || index >= this.issue.items.length) return;
			this.issue.items[index].is_exclusive = is_exclusive;
			this.trigger('change:issue:exclusive');
		},

		/* item type
		 * ===================== */
		setItemType: function(type) {
			this.issue.option_type = type;
			switch(type) {
				case 0: this.setMinMax(1, 1); break;
				case 1: this.setMinMax(0, 100); break;
				case 2: this.setMinMax(this.issue.min_choice, this.issue.min_choice); break;
				case 3: this.setMinMax(0, this.issue.max_choice); break;
				case 4: this.setMinMax(this.issue.min_choice, 100); break;
				case 5: this.setMinMax(this.issue.min_choice, this.issue.max_choice); break;
			}
			this.trigger('change:issue:option_type');
		},
		setMinMax: function(min, max) {
			if(isNaN(min)) min = 0;
			if(isNaN(max)) max = this.itemsHandler.itemCount();
			var count = this.issue.items.length;
			switch(this.issue.option_type) {
				case 0: min = 1; max = 1; break;
				case 1: min = 0; max = 100; break;
				case 2: if(min > count) min = count; max = min; break;
				case 3: min = 0; if(max > count) max = count; break;
				case 4: if(min > count) min = count; max = 100; break;
				case 5: if(max > count) max = count; if(min > max) min = max; break;
			}
			this.issue.min_choice = min;
			this.issue.max_choice = max;
			this.trigger('change:issue:min_max');
		},

		/* =========================== *
		 * Handle sub questions
		 * =========================== */
		_newRow: function(model, content) {
			return {
				id: $.util.uid(),
				content: content ? content : $.richtext.defaultValue('新问题')
			};
		},

		/* Random sub question
		 * ============================ */
		setSubQuestionRandom: function(random) {
			this.issue.is_row_rand = random;
			this.trigger('change:issue:random_row');
		},

		/* Sub question row num per group
		 * ============================ */
		setSubQuestionGroup: function(num_per_group) {
			this.issue.row_num_per_group = num_per_group;
			this.trigger('change:issue:row_num_per_group');
		},

		/* Sub question style
		 * ============================ */
		setSubQuestionStyle: function(style) {
			this.issue.show_style = style;
			this.trigger('change:issue:show_style_row');
		},

		/* ===========================
		 * Serialize the model to array codes. 
		 * Deserialize the model from array codes.
		 * =========================== */
		_serialize: function() {
			var codes = this.rowsHandler._serialize_items();
			codes.push('');
			return codes.concat(this.itemsHandler._serialize_items());
		},
		_deserialize: function(item_codes) {
			item_codes = item_codes.skipBlank();
			var bound = _.findIndex(item_codes, function(str) {
				return str == ''
			});
			if(bound == -1) bound = item_codes.length;
			var sub_questions = item_codes.slice(0, bound);
			var items = item_codes.slice(bound, item_codes.length);
			// update sub questions
			this.rowsHandler._deserialize_items(sub_questions);
			// update items
			this.itemsHandler._deserialize_items(items);
		},

		_getInfo: function() {
			switch(this.issue.option_type) {
				case 2: return '每行选择 ' + this.issue.min_choice + ' 项';
				case 3: return '每行最多选择 ' + this.issue.max_choice + ' 项';
				case 4: return '每行至少选择 ' + this.issue.min_choice + ' 项';
				case 5: return '每行选择 ' + this.issue.min_choice + ' 到 ' + this.issue.max_choice + ' 项';
			}
			return null;
		},

		_checkAnswer: function(answer) {
			for (var i = 0; i < this.issue.rows.length; i++) {
				var row = this.issue.rows[i];
				if(answer[row.id] == undefined) return '请回答所有子问题';
				switch(this.issue.option_type) {
					case 0: case 2:
						if(answer[row.id].length != this.issue.min_choice) return '每行请选择 ' + this.issue.min_choice + ' 项';
					default:
						if(answer[row.id].length < this.issue.min_choice) return '每行至少选择 ' + this.issue.min_choice + ' 项';
						if(answer[row.id].length > this.issue.max_choice) return '每行最多选择 ' + this.issue.max_choice + ' 项';
				}
			};
			return null;
		}
	});

});