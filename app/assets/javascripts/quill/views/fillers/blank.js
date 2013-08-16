//=require ../../templates/fillers/blank_sub_q

/* ================================
 * View: Blank question editor
 * ================================ */

$(function(){
	
	quill.quillClass('quill.views.fillers.Blank', quill.views.fillers.Base, {
		
		_render: function() {
			var con = this.$('.q-content');

			// remove q-info
			this.$('.q-info').remove();

			// shuffle items if necessary
			var indexes = _.range(this.model_issue.items.length);
			if(this.model_issue.is_rand)
				var indexes = _.shuffle(indexes);

			if(this.model_issue.show_style != 0) 
				con = $('<table cellpadding="0" cellspacing="0" />').appendTo(con);

			for (var i = 0; i < this.model_issue.items.length; i++) {
				var sub_q = this.model_issue.items[indexes[i]];
				var sub_con = this.hbs({
					title: sub_q.content.text,
					info: '（' + this.model.getSubInfo(sub_q.id) + '）',
					table: this.model_issue.show_style != 0,
					show_style: this.model_issue.show_style
				}, 'blank_sub_q').appendTo(con);
				this['_setup' + sub_q.data_type](sub_q, $('.sub-q-con', sub_con));
			};
		},

		_setupText: function(sub_question, con) {
			var ipt = sub_question.properties.has_multiple_line ? $('<textarea />') : $('<input type="text" />');
			ipt.attr('id', sub_question.id).appendTo(con);
			switch(this.model_issue.size) {
				case 0: ipt.css({width: '230px'}); break;
				case 1: ipt.css({width: '350px'}); break;
				case 2: ipt.css({width: '500px'}); break;
			}
		},

		_setupNumber: function(sub_question, con) {
			var ipt = $('<input class="short" type="text" />').attr('id', sub_question.id);
			var unit = $('<span />').text(sub_question.properties.unit);
			switch(sub_question.properties.unit_location) {
				case 0: ipt.appendTo(con); break;
				case 1: 
					ipt.appendTo(con);
					unit.appendTo(con).css({marginLeft: '10px'});
					break;
				case 2: 
					unit.appendTo(con).css({marginRight: '10px'});
					ipt.appendTo(con);
					break;
			}
		},

		_setupUrl: function(sub_question, con) {
			$('<input class="normal" type="text" />').attr({
				id: sub_question.id,
				placeholder: "例如：www.baidu.com"
			}).placeholder().appendTo(con);
		}, 

		_setupTime: function(sub_question, con) {
			$.od.odTimeSelector({
				format: sub_question.properties.format,
				min: sub_question.properties.min,
				max: sub_question.properties.max
			}).appendTo(con).attr('id', sub_question.id);
			$('<div class="cl-line" />').appendTo(con);
		},

		_setupPhone: function(sub_question, con) {
			var hint = '';
			switch(sub_question.properties.phone_type) {
				case 1: hint = '例如：010-8888-8888'; break;
				case 2: hint = '例如：186-8888-8888'; break;
				case 3: hint = '例如：010-8888-8888 或 186-8888-8888'; break;
			}
			$('<input class="normal" type="text" />').attr({
				id: sub_question.id,
				placeholder: hint
			}).placeholder().appendTo(con);
		},

		_setupAddress: function(sub_question, con) {
			var handler = this.model.loadHandler(sub_question.id);
			$.od.odAddressSelector({
				precision: handler.getFormat(),
				has_postcode: sub_question.properties.has_postcode
			}).appendTo(con).attr('id', sub_question.id);
		},

		_setupEmail: function(sub_question, con) {
			$('<input class="normal" type="text" />').attr({
				id: sub_question.id,
				placeholder: '例如：myemail@sina.com'
			}).placeholder().appendTo(con);
		},

		setAnswer: function(answer) {
			if(!answer) return;
			var bound = answer.length;
			if(bound > this.model_issue.items.length)
				bound = this.model_issue.items.length;
			for (var i = 0; i < bound; i++) {
				var item = this.model_issue.items[i];
				var ipt = this.$('#' + item.id);
				switch(item.data_type) {
					case 'Text': case 'Number': ipt.val(answer[i]); break;
					case 'Url': case 'Phone': case 'Email': ipt.val(answer[i]) ;break;
					case 'Time': ipt.odTimeSelector('val', answer[i]); break;
					case 'Address': ipt.odAddressSelector('val', answer[i]); break;
				}
			};
		},
		_getAnswer: function() {
			var answer = [];
			for (var i = 0; i < this.model_issue.items.length; i++) {
				var item = this.model_issue.items[i];
				var ipt = this.$('#' + item.id);
				var a = null;
				switch(item.data_type) {
					case 'Text': a = ipt.val(); break;
					case 'Number': a = parseFloat($.trim(ipt.val())); break;
					case 'Url': case 'Phone': case 'Email': a = ipt.val() ;break;
					case 'Time': a = ipt.odTimeSelector('val'); break;
					case 'Address': a = ipt.odAddressSelector('val'); break;
				}
				answer.push(a);
			};
			return answer;
		}
		
	});
	
});
