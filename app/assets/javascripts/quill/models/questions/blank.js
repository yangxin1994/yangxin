/* ================================
 * Model: Blank Question
 * ================================ */

$(function(){
	
	quill.quillClass('quill.models.questions.Blank', quill.models.questions.Base, {

		/* Default properties
		 * =========================== */
		_defaults: {
			issue: {
				show_style: 1		//可以是0（紧凑显示），1（子标题右对齐），2（子标题中对齐），或者3（子标题左对齐）
			}
		},

		_initialize: function() {
			$.extend(this, quill.modules.items(this, 'item', false, this._newSubQuestion));

			$.extend(this, quill.modules.rand(this, this.issue));

			var items = this.getItems();
			for (var i = 0; i < items.length; i++) {
				this.loadHandler(items[i].id);		// setup the init values for items
			};
		},

		_newSubQuestion: function(model, content) {
			var sub_q = {
				id: $.util.uid(),
				content: content ? content : $.richtext.defaultValue('新选项'),
				data_type: 'Text',
				properties: { }
			};
			quill.modules[sub_q.data_type.toLowerCase()](this, sub_q.properties);
			return sub_q;
		},

		loadHandler: function(id) {
			var item = this.findItem(id);
			return item ? quill.modules[item.data_type.toLowerCase()](this, item.properties) : null;
		},
		getHandlerItem: function(handler) {
			var items = this.getItems();
			for (var i = 0; i < items.length; i++) {
				if(items[i].properties == handler.target) {
					return items[i];
				}
			};
			return null;
		},

		/* Item data_type
		 * ['文本填充题', '数值填充题', '邮箱题', '链接题', '电话题', '时间题', '地址题']
		 * ============================= */
		setDataType: function(id, data_type) {
			var item = this.findItem(id);
			if(!item || item.data_type == data_type) return;
			item.data_type = data_type;
			this.trigger('change:items:data_type', id);
		},

		/* Show style
		 * ============================= */
		setStyle: function(style) {
			if(style == this.issue.show_style) return;
			this.issue.show_style = style;
			this.trigger('change:issue:show_style');
		},

		/* Serialize the model to array codes. 
		 * Deserialize the model from array codes.
		 * =========================== */
		_serialize: function() {
			return this._serialize_items();
		},
		_deserialize: function(item_codes) {
			this._deserialize_items(item_codes);
		},

		getSubInfo: function(sub_id) {
			var handler = this.loadHandler(sub_id);
			var sub_q = this.findItem(sub_id);
			return handler._getInfo ? handler._getInfo() : 
				quill.helpers.QuestionType.getLabel(quill.helpers.QuestionType.getValue(sub_q.data_type + 'Blank'));
		},

		_checkAnswer: function(answer) {
			if(answer.length != this.issue.items.length) return {index: 0, text:'请完成所有子题目'};
			for (var i = 0; i < this.issue.items.length; i++) {
				var item = this.issue.items[i];
				if(answer[i] == null)
					return {index: 0, text:'请完成所有子题目'};
				var error = this.loadHandler(item.id)._checkAnswer(answer[i]);
				if(error)
					return {index: i + 1, text: error};
			};
			return null;
		}

	});

});