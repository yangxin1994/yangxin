//=require ../../templates/fillers/matrix_choice_option

/* ================================
 * View: MatrixChoice question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.MatrixChoice', quill.views.fillers.Base, {
		
		_render: function() {
			var con = this.$('.q-content');

			// shuffle rows and items if necessary
			var row_indexes = _.range(this.model_issue.rows.length);
			if(this.model_issue.is_row_rand)
				var row_indexes = _.shuffle(row_indexes);
			var item_indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				var item_indexes = _.shuffle(item_indexes);

			// setup options
			var type = (this.model_issue.option_type == 0) ? 'radio' : 'checkbox';
			var r_count = (this.model_issue.row_num_per_group <= 0) ? 
				row_indexes.length : this.model_issue.row_num_per_group;
			var tb_count = Math.ceil(row_indexes.length / r_count);

			for (var i = 0; i < tb_count; i++) {
				// table
				var tb = $('<table cellspacing="0" cellpadding="0" />').appendTo(con);
				if(i == tb_count - 1) tb.addClass('last');

				// header
				var tr = $('<tr />').appendTo(tb);
				$('<th class="head" />').appendTo(tr);
				for (var c = 0; c < item_indexes.length; c++) {
					var item = this.model_issue.items[item_indexes[c]];
					var th = $('<th class="head" />').html($.richtext.textToHtml(item.content)).appendTo(tr);
					this.renderMediaPreviews(th, item.content);
				}

				// rows
				for (var r = 0; r < r_count; r++) {
					var ridx = i * r_count + r;
					if(ridx >= row_indexes.length) break;

					var row = this.model_issue.rows[row_indexes[ridx]];
					// row head
					var tr = $('<tr />').appendTo(tb);
					if(r % 2 == 1) tr.addClass('alter');
					var th = $('<th />').addClass('row_' + this.model_issue.show_style).html($.richtext.textToHtml(row.content)).appendTo(tr);
					this.renderMediaPreviews(th, row.content);
					// row option
					for (var c = 0; c < item_indexes.length; c++) {
						var item = this.model_issue.items[item_indexes[c]];
						var td = $('<td />').appendTo(tr);
						this.hbs({
							group_id: this.model.id + '_' + row.id,
							id: item.id,
							type: type,
							is_exclusive: item.is_exclusive
						}, '/fillers/matrix_choice_option', true).appendTo(td);
					};
					// set exclusive
					var set_exclusive = $.proxy(function(tr, ipt) {
						ipt.change($.proxy(function() {
							if(ipt.is(':checked')) {
								if(ipt.hasClass('is_exclusive')) {
									$('input:checkbox', tr).attr('checked', null);
									ipt.attr('checked', 'checked');
								} else {
									$('input:checkbox.is_exclusive', tr).attr('checked', null);
								}
							}
						}, this));
					}, this);
					$.each($('input:checkbox', tr), function(){
						set_exclusive(tr, $(this));
					});
				};
			};
		},

		setAnswer: function(answer) {
			if(!answer) return;
			for (var i = 0; i < this.model_issue.rows.length; i++) {
				var row = this.model_issue.rows[i];
				var group_id = this.model.id + '_' + row.id;
				for(var k=0; k<answer[row.id].length; k++) {
					this.$('#option_' + group_id + '_' + answer[row.id][k]).attr('checked', 'checked');
				}
			};
		},
		_getAnswer: function() {
			var answer = {};
			for (var i = 0; i < this.model_issue.rows.length; i++) {
				var row = this.model_issue.rows[i];
				var group_id = this.model.id + '_' + row.id;
				var row_answer = [];
				for(var k=0; k<this.model_issue.items.length; k++) {
					if(this.$('#option_' + group_id + '_' + this.model_issue.items[k].id).is(":checked")) {
						row_answer.push(this.model_issue.items[k].id);
					}
				}
				answer[row.id] = row_answer;
			};
			return answer;
		}
		
	});
	
});
