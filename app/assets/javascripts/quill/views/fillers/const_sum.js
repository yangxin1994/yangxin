//=require ../../templates/fillers/const_sum_tb
//=require ../../templates/fillers/const_sum_tr

/* ================================
 * View: ConstSum question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.ConstSum', quill.views.fillers.Base, {
		
		_render: function() {
			var con = this.$('.q-content');

			// shuffle items if necessary
			var indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				var indexes = _.shuffle(indexes);
			var other_item = this.model_issue.other_item;
			if(other_item && !other_item.has_other_item) other_item = null;

			// setup options
			var tb = this.hbs(this.model_issue, '/fillers/const_sum_tb', true).appendTo(con);
			var total_count = this.model.itemCount();
			var _setup_item = $.proxy(function(i) {
				var item = (i < this.model_issue.items.length) ? this.model_issue.items[i] : other_item;
				var tr = this.hbs(item, '/fillers/const_sum_tr', true).insertBefore($('.sum', tb));
				if(i == this.model_issue.items.length) {
					$('<input class="cs_other" type="text" />').attr({
						placeholder: item.content.text
					}).placeholder().appendTo($('th', tr));
				} else {
					$('th', tr).html($.richtext.textToHtml(item.content));
				}
				this.renderMediaPreviews($('th', tr), item.content);
			}, this);
			for (var i = 0; i < indexes.length; i++)
				_setup_item(indexes[i]);
			if(other_item) _setup_item(indexes.length);


			$('td input', con).blur(function() {
				var $sum = $(".sum td", con);
				if(isNaN($(this).val())) {
					$sum.text("含非数字");
				} else {
					var total = 0;
					$('td input', con).each(function() {
						total += Number($(this).val());
					});
					if(!isNaN(total))
						$sum.text(total);
				};
			});
		},

		_setAnswer: function(answer) {
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
