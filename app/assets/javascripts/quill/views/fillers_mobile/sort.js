//=require ../../templates/fillers_mobile/sort_op

/* ================================
 * View: Sort question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillersMobile.Sort', quill.views.fillersMobile.Base, {
		
		_render: function() {
			// proper warm reminder for mobile sort
			var info = this.$('.q-info').text();
			this.$('.q-info').text(info.replace(/拖放选项/g, "点击箭头"));

			var con = this.$('.q-content');

			// shuffle items if necessary
			var indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				var indexes = _.shuffle(indexes);
			var other_item = this.model_issue.other_item;
			if(other_item && !other_item.has_other_item) other_item = null;

			// setup options
			var setup_item = $.proxy(function(i) {
				var item = (i < this.model_issue.items.length) ? this.model_issue.items[i] : other_item;
				var $p = this.hbs({
					item_id: item.id
				}, '/fillers_mobile/sort_op', true).appendTo(con);
				this.renderMediaPreviews($p, item.content);
				if(i == this.model_issue.items.length) {
					$('<input type="text" class="sort_other" />').attr({
						placeholder: item.content.text
					}).placeholder().appendTo($('.sort-item', $p));
				} else {
					str    = $.richtext.textToHtml(item.content);
					output = str.chunk(6).join('<br/>')
					console.log(output)
					$('.sort-item', $p).html(output);
				};
			}, this);

			for (var i = 0; i < indexes.length; i++)
				setup_item(indexes[i]);
			if(other_item) setup_item(indexes.length);
			this.refreshSortIndex();


			$('.top-btn', con).click(this, function() {
				var p = $(this).parent().parent().parent();
				var filler = p.parent().parent().data('view');
				p.insertBefore(p.prev());
				filler.refreshSortIndex();
			});
			$('.bottom-btn', con).click(this, function() {
				var p = $(this).parent().parent().parent();
				var filler = p.parent().parent().data('view');
				p.insertAfter(p.next());
				filler.refreshSortIndex();
			});	
		},

		refreshSortIndex: function() {
			if(this.model_issue.min <= 0 && this.model_issue.max <= 0) {
				this.$('.idx').hide();
			} else {
				this.$('.idx').empty().removeClass('max');
				var min = this.model_issue.min, max = this.model_issue.max;
				if(min <= 0) min = 1;
				if(max <= 0) max = this.model.itemCount();
				for (var i = 0; i < max; i++) {
					this.$('.idx:eq(' + i + ')').text((i+1).toString() + ".");
				};
				this.$('.idx:gt(' + (min-1) + ')').addClass('max');
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
						dom.prependTo(this.$('.q-content'));
					else
						dom.insertAfter($('p:eq(' + (i-1) + ')', this.$('.q-content')));
				};
			}
			this.refreshSortIndex();
		},
		_getAnswer: function() {
			var answer = { sort_result: [] };
			var max = this.model_issue.max;
			if(max <= 0) max = this.$('.q-content p').length;
			$.each(this.$('.q-content p:lt(' + max + ')'), function(i, v) {
				answer.sort_result[i] = $(v).attr('id');
			});
			if(this.model_issue.other_item && this.model_issue.other_item.has_other_item) {
				answer.text_input = $.trim(this.$('input:text').val());
			}
			return answer;
		}
		
	});
	
});
