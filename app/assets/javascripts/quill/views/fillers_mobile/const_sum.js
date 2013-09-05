//=require ../../templates/fillers_mobile/const_sum

/* ================================
 * View: ConstSum question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillersMobile.ConstSum', quill.views.fillersMobile.Base, {
		
		_render: function() {
			var $p = $('<p />').appendTo(this.$('.q-content'));

			// shuffle items if necessary
			var indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				var indexes = _.shuffle(indexes);
			var other_item = this.model_issue.other_item;
			if(other_item && !other_item.has_other_item) other_item = null;

			// setup options
			var setup_item = $.proxy(function(i) {
				var item = (i < this.model_issue.items.length) ? this.model_issue.items[i] : other_item;
				var $span = this.hbs({
					item_id: item.id,
					item_text: $.richtext.textToHtml(item.content)
				}, '/fillers_mobile/const_sum', true).appendTo($p);
				if(i == this.model_issue.items.length) {
					$('<span class="other"><input class="cs_other" type="text" /></span>').insertAfter($('label', $span));
				};
				this.renderMediaPreviews($span, item.content);
			}, this);

			for (var i = 0; i < indexes.length; i++)
				setup_item(indexes[i]);
			if(other_item) setup_item(indexes.length);

			$('.bg input', this.$('.q-content')).focus(function() {
				var $bg = $(this).parent().parent();
				$bg.siblings().removeClass('bea');
				$bg.addClass('bea');
			});
		},

		setAnswer: function(answer) {
			if(!answer) return;
			this.$('.cs_other').val(answer.text_input);

			for (var i = 0; i < this.model_issue.items.length; i++) {
				var id = this.model_issue.items[i].id;
				this.$('#' + id).val(answer[id]);
			};
			if(this.model_issue.other_item && this.model_issue.other_item.has_other_item) {
				var id = this.model_issue.other_item.id;
				this.$('#' + id).val(answer[id]);
			}
		},
		_getAnswer: function() {
			var answer = {};

			function _get(id) {
				answer[id] = parseFloat($.trim(this.$('#' + id).val()));
				if(isNaN(answer[id]))
					answer[id] = 0;
			}
			for (var i = 0; i < this.model_issue.items.length; i++) {
				_get(this.model_issue.items[i].id);
			};
			if(this.model_issue.other_item && this.model_issue.other_item.has_other_item) {
				_get(this.model_issue.other_item.id);
				answer.text_input = $.trim(this.$('.cs_other').val());
			}
			return answer;
		}

	});
	
});
