//=require ../../templates/fillers/choice_option

/* ================================
 * View: Choice question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.Choice', quill.views.fillers.Base, {
		
		_render: function() {
			var con = this.$('.q-content');

			// shuffle items if necessary
			var indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				var indexes = _.shuffle(indexes);
			var other_item = this.model_issue.other_item;
			if(other_item && !other_item.has_other_item) other_item = null;

			// setup options
			if(this.model_issue.option_type == 1) {
				// render selector
				var slt = $('<select />').appendTo(con);
				$('<option value="-1" />').text('- 请选择 -').appendTo(slt);
				$.each(indexes, $.proxy(function(i, index) {
					var item = this.model_issue.items[index];
					$('<option value=' + item.id + ' />').text(item.content.text).appendTo(slt);
				}, this));
				if(other_item) {
					$('<option value=' + other_item.id + ' />').text(other_item.content.text).appendTo(slt);
					$('<input type="text" />').hide().appendTo(con);
					slt.change($.proxy(function() {
						// show input if necessary
						(parseInt(slt.val()) == other_item.id) ? this.$('input:text').show() : this.$('input:text').hide();
					}, this));
				}
				// setup medias
				$.each(indexes, $.proxy(function(i, index) {
					var item = this.model_issue.items[index];
					var div_dom = $('<div class="opt-media-con" />').attr('id', 'media_' + this.model.id + '_' + item.id).hide().appendTo(con);
					this.renderMediaPreviews(div_dom, item.content);
				}, this));
				if(other_item) {
					var div_dom = $('<div class="opt-media-con" />').attr('id', 'media_' + this.model.id + '_' + other_item.id).hide().appendTo(con);
					this.renderMediaPreviews(div_dom, other_item.content);
				}
				this.$('.opt-media-con:eq(0)').show();
				slt.change($.proxy(function() {
					this.$('.opt-media-con').hide();
					this.$('#media_' + this.model.id + '_' + slt.val()).show();
				}, this));
			} else {
				// render radio/checkbox
				var type = (this.model_issue.option_type == 0) ? 'radio' : 'checkbox';
				var total_count = this.model.itemCount(),
						c_count = (this.model_issue.choice_num_per_row > 0) ? this.model_issue.choice_num_per_row : 1,
				    r_count = Math.ceil(total_count / c_count);
				var tb = $('<table />').appendTo(con);
				for (var r = 0; r < r_count; r++) {
					var tr = $('<tr />').appendTo(tb);
					for (var c = 0; c < c_count; c++) {
						var td = $('<td />').appendTo(tr);
						var idx = r * c_count + c;
						if(idx >= total_count) continue;
						var item = (idx < this.model_issue.items.length) ? 
							this.model_issue.items[indexes[idx]] : other_item;
						var opt = this.hbs({
							group_id: this.model.id,
							id: item.id,
							type: type,
							html: $.richtext.textToHtml(item.content),
							input: item.has_other_item,
							is_exclusive: item.is_exclusive
						}, '/fillers/choice_option', true).appendTo(td);
						this.renderMediaPreviews(opt, item.content);
						$('input', opt).data('value', item.id);
						if(idx == this.model_issue.items.length) {
							// if text input is focus, check the checkbox.
							$('input:checkbox', opt).change(function() {
								if($('input:text', $(this).parent()).is(":focus")) {
									$(this).attr('checked', 'checked');
								}
							});
						}
					};
				};
				// set exclusive
				var set_exclusive = $.proxy(function(ipt) {
					ipt.change($.proxy(function() {
						if(ipt.is(':checked')) {
							if(ipt.hasClass('is_exclusive')) {
								this.$('input:checkbox').attr('checked', null);
								ipt.attr('checked', 'checked');
							} else {
								this.$('input:checkbox.is_exclusive').attr('checked', null);
							}
						}
					}, this));
				}, this);
				$.each(this.$('input:checkbox'), function(){
					set_exclusive($(this));
				});
			}
		},

		setAnswer: function(answer) {
			if(!answer) return;
			if(answer.selection && answer.selection.length > 0) {
				if(this.model_issue.option_type == 1) {
					this.$('select').val(answer.selection[0]);
					this.$('.opt-media-con').hide();
					this.$('#media_' + this.model.id + '_' + answer.selection[0]).show();
					if(this.model_issue.other_item && _.contains(answer.selection, this.model_issue.other_item.id)) {
						this.$('input:text').show();
					}
				} else {
					for (var i = 0; i < answer.selection.length; i++) {
						this.$('#option_' + this.model.id + '_' + answer.selection[i]).attr('checked', 'checked');
					};
				}
			}
			this.$('input:text').val(answer.text_input);
		},
		_getAnswer: function() {
			var answer = {selection: [], text_input: ''};
			if(this.model_issue.option_type == 1) {
				this.$('select option:selected').each(function () {
					var v = parseInt($(this).val(), 10);
					if (v > 0) answer.selection.push(v);
				});
			} else {
				this.$('input:checked').each(function(i, v) {
					var v = $(this).data('value');
					if (v != null) answer.selection.push(v);	// in case some browser does not support jQuery.data
				});
			}
			console.log(answer);
			if(this.model_issue.other_item && _.contains(answer.selection, this.model_issue.other_item.id)) {
				answer.text_input = $.trim(this.$('input:text').val());
			};
			return answer;
		}

	});
	
});
