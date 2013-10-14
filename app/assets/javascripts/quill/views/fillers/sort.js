//=require ../../templates/fillers/sort
//=require ../../templates/fillers/sort_left
//=require ../../templates/fillers/sort_right
//=require ../../templates/fillers/sort_item

/* ================================
 * View: Sort question filler
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.Sort', quill.views.fillers.Base, {
		
		_render: function() {
			this.hbs(null, '/fillers/sort', true).appendTo(this.$('.q-content'));

			// setup left options
			var min = this.model_issue.min, max = this.model_issue.max, idx = 0;
			if(min <= 0) min = 0;
			if(max <= 0) max = this.model_issue.items.length + (this.model.hasOther() ? 1 : 0);
			var _setup_left = $.proxy(function(idx, type) {
				var dom = this.hbs({index: idx + 1, type: type}, '/fillers/sort_left', true).appendTo(this.$('.sort-left'));
				dom.droppable({
					scope: this.model.id,
					hoverClass: 'sort-type-hover',
					tolerance: 'pointer',
					drop: $.proxy(function(event, ui) {
						var idx = ui.draggable.data('item-index');
						this._move_item_to_left(idx, dom);
						dom.droppable('disable');
					}, this)
				});
			}, this);
			for (; idx < min; idx++) { _setup_left(idx, 'require'); };
			for (; idx < max; idx++) { _setup_left(idx, 'option'); };

			// setup right options
			// shuffle items if necessary
			var indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				indexes = _.shuffle(indexes);
			if(this.model.hasOther())
				indexes.push(indexes.length);
			for (var i = 0; i < indexes.length; i++) {
				var idx = indexes[i];
				var li = this.hbs(this._get_item(indexes[i]), '/fillers/sort_right', true).appendTo(this.$('.sort-right'));
				var dom = this._setup_item(idx).appendTo(li);
				dom.draggable({
					scope: this.model.id,
					helper: "clone",
					start: $.proxy(function(event, ui) {
						ui.helper.addClass('dragged');
						dom.hide();
					}, this),
					stop: function(event, ui) { dom.show(); }
				});
			};
		},

		_get_item: function(index) {
			return (index < this.model_issue.items.length) ? this.model_issue.items[index] : this.model_issue.other_item;
		},
		_setup_item: function(index) {
			var item = this._get_item(index);
			var dom = this.hbs(item, '/fillers/sort_item', true);
			if(index == this.model_issue.items.length) {
				var ipt = $('<input type="text" />').attr({ placeholder: item.content.text }).placeholder().blur(function() {
					item.input_value = $.trim($(this).val());
				}).appendTo($('.sort-item-detail', dom));
				if(item.input_value != '') ipt.val(item.input_value);
			} else {
				$('.sort-item-detail', dom).html($.richtext.textToHtml(item.content));
			}
			this.renderMediaPreviews($('.sort-item-detail', dom), item.content);
			dom.data('item-index', index);
			return dom;
		},
		_remove_left_item: function(left_li) {
			if(left_li.length == 0) return;
			var dom = $('.sort-item', left_li);
			if(dom.length == 0) return;
			var index = dom.data('item-index');
			this.$('.sort-right li:eq(' + index + ')').show();
			dom.remove();
			left_li.droppable('enable');
		},
		_move_item_to_left: function(index, left_li) {
			if(left_li.length == 0) return;
			this.$('.sort-left li').each($.proxy(function(i, v) {
				var dom = $('.sort-item', $(v));
				if(dom.length > 0 && dom.data('item-index') == index)
					this._remove_left_item($(v));
			}, this));
			var right_li = this.$('.sort-right li:eq(' + index + ')').hide();
			var dom = this._setup_item(index).appendTo($('.sort-item-con', left_li));
			$('<em />').addClass('sort-item-remove').appendTo(dom).click($.proxy(function() {
				this._remove_left_item(left_li);
			}, this));
			dom.draggable({
				scope: this.model.id,
				helper: "clone",
				start: $.proxy(function(event, ui) {
					ui.helper.css('zIndex', 2000);
					$('.sort-item-remove', ui.helper).remove();
				}, this)
			});
		},

		setAnswer: function(answer) {
			if(!answer) return;

			if(this.model.hasOther()) {
				this.$('input:text').val(answer.text_input);
				this.model_issue.other_item.input_value = answer.text_input;
			}
			
			if(answer.sort_result) {
				for (var i = 0; i < answer.sort_result.length; i++) {
					var idx = this.model.findItemIndex(answer.sort_result[i]);
					if(idx == -1) {
						if(answer.sort_result[i] == this.model_issue.other_item.id)
							idx = this.model_issue.items.length;
						else
							continue;
					}
					this._move_item_to_left(idx, this.$('.sort-left li:eq(' + i + ')'));
				};
			}
		},
		_getAnswer: function() {
			var answer = { sort_result: [] };

			var max = this.$('.sort-left li.sort-type-require').length;
			var min = this.$('.sort-left li').length - max;
			this.$('.sort-left li').each(function(i, v){
				var dom = $('.sort-item', $(v));
				if(dom.length == 0) {
					answer.sort_result.push(undefined);
				} else {
					answer.sort_result.push(dom.attr('id'));
				}
			});
			while(answer.sort_result.length > 0 && answer.sort_result[answer.sort_result.length - 1] == undefined)
				answer.sort_result.pop();

			if(this.model.hasOther())
				answer.text_input = $.trim(this.$('input:text').val());

			return answer;
		}
		
	});
	
}); 