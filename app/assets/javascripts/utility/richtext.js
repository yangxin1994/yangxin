/* ================================
 * Provide richtext related methods
 * ================================ */
(function($){

	$.richtext = $.richtext || {
		defaultValue: function(text) {
			return {
				text: text,
				image: [],
				audio: [],
				video: []
			};
		},

		print: function(rt) {
			if(rt == null) return null;
			return rt.text.replace(/\r\n|\r|\n/igm, '')
				.replace(/^<c>(.*)<\/c>$/igm, '$1')
				.replace(/<b>(.*?)<\/b>/igm, '$1')
				.replace(/<i>(.*?)<\/i>/igm, '$1')
				.replace(/<r>(.*?)<\/r>/igm, '$1')
				.replace(/<u>(.*?)<\/u>/igm, '$1')
				.replace(/<big>(.*?)<\/big>/igm, '$1')
				.replace(/<bigger>(.*?)<\/bigger>/igm, '$1')
				.replace(/<biggest>(.*?)<\/biggest>/igm, '$1')
				.replace(/<link>([^\s]*?)<\/link>/igm, '$1')
				.replace(/<link>([^\s]*?)\s(.*?)<\/link>/igm, '$2')
				+ _.map([['image', '图'], ['video', '视'], ['audio', '音']], function(v) {
					var title = '';
					if(rt[v[0]] != null) {
						for (var k = 0; k < rt[v[0]].length; k++) {
							title += (' [' + v[1] + ']');
						};
					}
					return title;
				}).join('');
		},

		textToHtml: function(rt) {
			if(rt == null || rt.text == null) return null;
			// 1. replace \r and \n
			var html = rt.text.replace(/\r\n|\r|\n/igm, '<br />');
			// 2. test whether text align center or not
			var center = /^<c>.*<\/c>$/igm.test(html);
			// 3. get real html
			var html = $('<div />').text(html).html()
				.replace(/&lt;br \/&gt;/igm, '<br />')
				.replace(/^(&lt;c&gt;)(.*)(&lt;\/c&gt;)$/igm, '$2')
				.replace(/(&lt;b&gt;)(.*?)(&lt;\/b&gt;)/igm, '<span style="font-weight: bold;">$2</span>')
				.replace(/(&lt;i&gt;)(.*?)(&lt;\/i&gt;)/igm, '<span style="font-style: italic;">$2</span>')
				.replace(/(&lt;r&gt;)(.*?)(&lt;\/r&gt;)/igm, '<span style="color: #f00">$2</span>')
				.replace(/(&lt;u&gt;)(.*?)(&lt;\/u&gt;)/igm, '<span style="text-decoration: underline">$2</span>')
				.replace(/(&lt;big&gt;)(.*?)(&lt;\/big&gt;)/igm, '<span style="font-size: 18px;">$2</span>')
				.replace(/(&lt;bigger&gt;)(.*?)(&lt;\/bigger&gt;)/igm, '<span style="font-size: 24px;">$2</span>')
				.replace(/(&lt;biggest&gt;)(.*?)(&lt;\/biggest&gt;)/igm, '<span style="font-size: 30px;">$2</span>')
				.replace(/(&lt;link&gt;)([^\s]*?)(&lt;\/link&gt;)/igm, '<a href="$2" style="color:#4183c4" target="_blank">$2</a>')
				.replace(/(&lt;link&gt;)([^\s]*?)\s(.*?)(&lt;\/link&gt;)/igm, '<a href="$2" style="color:#4183c4" target="_blank">$3</a>');
			return center ? ('<div ' + (center ? 'style="text-align: center"' : '') + '>' + html + '</div>') : html;
		}
	};

	// console.log($.richtext.print({text:'<c>asd<b>fa</b>sda<link>http://abc.com abc.com</link>sd <link>aasdf.com</link>fasdf</c>'}));
	// console.log($.richtext.textToHtml({text: '<b>abc</b><p>asdff</p><r>asdff</r><i>asd<r>asdff</r>ff</i>'}));

})(jQuery);