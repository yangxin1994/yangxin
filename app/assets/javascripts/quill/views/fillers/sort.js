//=require ../../templates/fillers/sort_option

/* ================================
 * View: Sort question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.Sort', quill.views.fillers.Base, {
		
		_render: function() {
			var ul = $('<ul />').appendTo(this.$('.q-content'));

			// shuffle items if necessary
			var indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				var indexes = _.shuffle(indexes);
			var other_item = this.model_issue.other_item;
			if(other_item && !other_item.has_other_item) other_item = null;

			// setup options
			var total_count = this.model.itemCount();
			var _setup_item = $.proxy(function(i) {
				var item = (i < this.model_issue.items.length) ? this.model_issue.items[i] : other_item;
				var li = this.hbs(item, '/fillers/sort_option', true).appendTo(ul);
				this.renderMediaPreviews(li, item.content);
				if(i == this.model_issue.items.length) {
					$('<input type="text" />').attr({
						placeholder: item.content.text
					}).placeholder().appendTo($('.sort-item', li));
				} else {
					$('.sort-item', li).html($.richtext.textToHtml(item.content));
				}
			}, this);
			for (var i = 0; i < indexes.length; i++)
				_setup_item(indexes[i]);
			if(other_item) _setup_item(indexes.length);
			this.refreshSortIndex();

			// make ul sortable
			ul.sortable({
				stop: $.proxy(function(event, ui) {
					this.refreshSortIndex();
				}, this)
			});
		},

		refreshSortIndex: function() {
			if(this.model_issue.min <= 0 && this.model_issue.max <= 0) {
				this.$('.sort-index').hide();
			} else {
				this.$('.sort-index').empty().removeClass('max');
				var min = this.model_issue.min, max = this.model_issue.max;
				if(min <= 0) min = 1;
				if(max <= 0) max = this.model.itemCount();
				for (var i = 0; i < max; i++) {
					this.$('.sort-index:eq(' + i + ')').text(i + 1);
				};
				this.$('.sort-index:gt(' + (min-1) + ')').addClass('max');
			}
		},

		setAnswer: function(answer) {
			if(!answer) return;
			this.$('input:text').val(answer.text_input);
			if(answer.sort_result) {
				for (var i = 0; i < answer.sort_result.length; i++) {
					var id = answer.sort_result[i];
					var dom = this.$('#' + id).detach();
					if(i == 0)
						dom.prependTo(this.$('.q-content ul'));
					else
						dom.insertAfter($('li:eq(' + (i-1) + ')', this.$('.q-content ul')));
				};
			}
			this.refreshSortIndex();
		},
		_getAnswer: function() {
			var answer = { sort_result: [] };
			var max = this.model_issue.max;
			if(max <= 0) max = this.$('.q-content li').length;
			$.each(this.$('.q-content li:lt(' + max + ')'), function(i, v) {
				answer.sort_result[i] = $(v).attr('id');
			});
			if(this.model_issue.other_item && this.model_issue.other_item.has_other_item) {
				answer.text_input = $.trim(this.$('input:text').val());
			}
			return answer;
		}
		
	});
	
});
