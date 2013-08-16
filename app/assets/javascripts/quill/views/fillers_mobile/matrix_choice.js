//=require ../../templates/fillers_mobile/matrix
//=require ../../templates/fillers_mobile/matrix_op

/* ================================
 * View: MatrixChoice question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillersMobile.MatrixChoice', quill.views.fillersMobile.Base, {
		
		_render: function() {
			var con = this.$('.q-content');

			// shuffle rows and items if necessary
			var row_indexes = _.range(this.model_issue.rows.length);
			if(this.model_issue.is_row_rand)
				var row_indexes = _.shuffle(row_indexes);
			var item_indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				var item_indexes = _.shuffle(item_indexes);
			var type = (this.model_issue.option_type == 0) ? 'radio' : 'checkbox';

			// setup options
			for(var i = 0; i < row_indexes.length; i ++) {
				var row = this.model_issue.rows[row_indexes[i]];
				var $div = this.hbs({
					row_id: this.model.id + '_' + row.id,
					row_text: row.content.text
				}, '/fillers_mobile/matrix', true).appendTo(this.$('.q-content'));
				this.renderMediaPreviews($('.subhead', $div), row.content);

				for (var c = 0; c < item_indexes.length; c++) {
					var item = this.model_issue.items[item_indexes[c]];
					var $p = this.hbs({
						row_id: this.model.id + '_' + row.id,
						item_id: item.id,
						item_text: $.richtext.textToHtml(item.content),
						type: type,
						is_exclusive: item.is_exclusive
					}, '/fillers_mobile/matrix_op', true).insertBefore($('.q-divide', $div));
					this.renderMediaPreviews($p, item.content);
				};
				if(i == (row_indexes.length - 1))
					$('.q-divide', $div).remove();

				// set exclusive
				var set_exclusive = $.proxy(function($div, ipt) {
					ipt.change($.proxy(function() {
						if(ipt.is(':checked')) {
							if(ipt.hasClass('is_exclusive')) {
								$('input:checkbox', $div).attr('checked', null);
								ipt.attr('checked', 'checked');
							} else {
								$('input:checkbox.is_exclusive', $div).attr('checked', null);
							}
						}
					}, this));
				}, this);
				$.each($('input:checkbox', $div), function(){
					set_exclusive($div, $(this));
				});				
			};
		},

		setAnswer: function(answer) {
			if(!answer) return;
			for (var i = 0; i < this.model_issue.rows.length; i++) {
				var row = this.model_issue.rows[i];
				var row_id = this.model.id + '_' + row.id;
				for(var k=0; k<answer[row.id].length; k++) {
					this.$('#' + row_id + '_' + answer[row.id][k]).attr('checked', 'checked');
				}
			};
		},
		_getAnswer: function() {
			var answer = {};
			for (var i = 0; i < this.model_issue.rows.length; i++) {
				var row = this.model_issue.rows[i];
				var row_id = this.model.id + '_' + row.id;
				var row_answer = [];
				for(var k=0; k<this.model_issue.items.length; k++) {
					if(this.$('#' + row_id + '_' + this.model_issue.items[k].id).is(":checked")) {
						row_answer.push(this.model_issue.items[k].id);
					}
				}
				answer[row.id] = row_answer;
			};
			return answer;
		}
		
	});
	
});
