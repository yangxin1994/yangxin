/* ================================
 * View: Scale question render
 * ================================ */

$(function(){
	
	function _removeSelected(dom) {
		dom.removeClass('selected level1 level2 level3 level4 level5 level6 level7');
	};

	quill.quillClass('quill.views.fillers.Scale', quill.views.fillers.Base, {
		
		_render: function() {
			var con = this.$('.q-content');

			// shuffle items if necessary
			var indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				var indexes = _.shuffle(indexes);

			// setup tables
			var r_count = (this.model_issue.item_num_per_group <= 0) ? 
				indexes.length : this.model_issue.item_num_per_group;
			var tb_count = Math.ceil(indexes.length / r_count);
			for (var i = 0; i < tb_count; i++) {
				// setup table
				var tb = $('<table cellpadding="0" cellspacing="0" />').appendTo(con);
				if(i == tb_count -1) tb.addClass('last');
				// labels
				var tr = $('<tr><th class="head"></th></tr>').appendTo(tb);
				for (var c = 0; c < this.model_issue.labels.length; c++) {
					$('<th class="head" />').text(this.model_issue.labels[c]).appendTo(tr);
				};
				if(this.model_issue.show_unknown) 
					$('<th class="head" />').text('').appendTo(tr);
				// items
				for(var r = 0; r < r_count; r++) {
					var ridx = i * r_count + r;
					if(ridx >= indexes.length) break;
					var item = this.model_issue.items[indexes[ridx]];
					tr = $('<tr />').attr('id', item.id).appendTo(tb);
					if(r % 2 == 1) tr.addClass('alter');
					var th = $('<th />').addClass('row_' + this.model_issue.show_style).html($.richtext.textToHtml(item.content)).appendTo(tr);
					this.renderMediaPreviews(th, item.content);
					for (var c = 0; c < this.model_issue.labels.length; c++) {
						$('<td />').text(c+1).appendTo(tr);
					};
					if(this.model_issue.show_unknown)
						$('<td class="set_unknown" />').text('不清楚').appendTo(tr);
				}
			};

			// set event
			$('td', con).hover(function() {
				$(this).addClass('hover').prevAll('td').addClass('hover');
			}, function() {
				$(this).removeClass('hover').prevAll('td').removeClass('hover');
			}).click(function() {
				var self = $(this);
				if(self.hasClass('set_unknown')) {
					_removeSelected(self);
					_removeSelected(self.siblings().removeClass('unknown'));
					self.prevAll('td').addClass('unknown').text('×');
				} else {
					_removeSelected(self.removeClass('unknown').siblings().removeClass('unknown'));
					self.addClass('selected').prevAll('td').addClass('selected');
					var selected_doms = $('.selected', self.parent());
					selected_doms.each(function() {
						$(this).addClass('level' + (7 - selected_doms.length + $(this).index()));
					});
					$.each($('td', self.parent()), function(i, v) {
						if(!$(v).hasClass('set_unknown')) $(v).text( i < selected_doms.length - 1 ? '' : (i + 1));
					});
				}
			});
		},

		_setAnswer: function(answer) {
			$.each(this.model_issue.items, $.proxy(function(i, item){
				var v = answer[item.id], tr = this.$('#' + item.id);
				if(v == undefined) return;
				if(v < 0) {
					if(this.model_issue.show_unknown) {
						$.each($('td', tr), function(k, td) {
							if(!$(td).hasClass('set_unknown')) $(td).addClass('unknown').text('×');
						});
					}
				} else {
					$('td:lt(' + (v+1) + ')', tr).addClass('selected').each(function() {
						$(this).addClass('level' + (7 - v - 1 + $(this).index()));
					});
					$('td:lt(' + v + ')', tr).text('');
				}
			}, this));
		},
		_getAnswer: function() {
			var answer = {};
			$.each(this.model_issue.items, $.proxy(function(i, item) {
				var tr = this.$('#' + item.id);
				var v = $('td.selected', tr).length;
				if(v > 0)
					answer[item.id] = v - 1;
				else {
					v = $('td.unknown', tr).length;
					if(v > 0 && this.model_issue.show_unknown)
						answer[item.id] = -1;
				}
			}, this));
			return answer;
		}

	});
	
});
