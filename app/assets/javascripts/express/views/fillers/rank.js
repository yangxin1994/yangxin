//=require ../../templates/fillers/rank_option
//=require ui/express_widgets/od_checkbox

/* ================================
 * View: Rank question render
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.Rank', quill.views.fillers.Base, {
		
		_render: function() {
			var con = this.$('.q-content');

			// shuffle items if necessary
			var indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				var indexes = _.shuffle(indexes);
			var other_item = this.model_issue.other_item;
			if(other_item && !other_item.has_other_item) other_item = null;

			// setup options
			var total_count = this.model.itemCount();
			var tb = $('<table cellpadding="0" cellspacing="0" />');
			// labels
			if(this.model.hasLabel()) {
				var tr = this.hbs(null, '/fillers/rank_option', true).appendTo(tb).removeClass();
				var td = $('td:eq(0)', tr).css({position: 'relative' });
				var each_w = (this.model_issue.icon_num - 1) * 24 / (this.model_issue.desc_ary.length - 1);
				for (var i = 0; i < this.model_issue.desc_ary.length; i++) {
					var txt = this.model_issue.desc_ary[i];
					var span = $('<span class="rank-icon-label" />').text(txt).appendTo(td);
					var left = i * each_w + 12 - (txt.length * 12) / 2;	// TODO: only support Chinese character size
					span.css('left', left + 'px');
				};
			}
			// items
			var _setup_item = $.proxy(function(i) {
				var item = (i < this.model_issue.items.length) ? this.model_issue.items[i] : other_item;
				var tr = this.hbs(null, '/fillers/rank_option', true).appendTo(tb);
				// head
				var td = $('th', tr);
				if(i == this.model_issue.items.length) {
					$('<input type="text" />').attr({
						placeholder: item.content.text
					}).placeholder().appendTo(td);
				} else {
					td.html($.richtext.textToHtml(item.content));
				}
				// icons
				td = $('td:eq(0)', tr);
				for(var k=0; k<this.model_issue.icon_num; k++) {
					var icon = $('<span class="rank-icon rank-icon-style-' + this.model_issue.icon + '" />').appendTo(td);
					$('<span class="forbidden" />').hide().appendTo(icon);
				}
				// unknown
				var ckb = $.od.odCheckbox({
					id: this._domId(item.id),
					text: '不清楚',
					onChange: $.proxy(function(checked) {
						var p = this._findDom(item.id).parents('tr');
						checked ? $('.forbidden', p).show() : $('.forbidden', p).hide();
					}, this)
				}).appendTo($('td:eq(1)', tr));
			}, this);
			for (var i = 0; i < indexes.length; i++)
				_setup_item(indexes[i]);
			if(other_item) _setup_item(indexes.length);

			tb.appendTo(con);
		}

	});
	
});
