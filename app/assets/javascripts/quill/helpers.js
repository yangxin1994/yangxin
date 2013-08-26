//= require ./base

$(function(){

	/* Helper methods
	 * ======================= */
	$.extend(window.quill.helpers, {
		
		QuestionType: (function() {
			var _type_names = ['Choice', 'MatrixChoice', 'TextBlank', 'NumberBlank', 'EmailBlank', 'UrlBlank', 'PhoneBlank',
				'TimeBlank', 'AddressBlank', 'Blank', 'MatrixBlank', 'ConstSum', 'Sort', 'Rank', 'Paragraph', 'File', 'Table', 'Scale'];
			var _type_labels = ['选择题', '矩阵选择题', '文本填充题', '数值填充题', '邮箱题', '链接题', '电话题', 
				'时间题', '地址题', '组合填充题', '矩阵填充题', '比重题', '排序题', '评分题', '文本段', '文件题', '表格填充题', '量表题'];

			return {
				getNames: function() { return _type_names; },

				getName: function (value) { return _type_names[value]; },

				getLabel: function (value) { return _type_labels[value]; },

				getValue: function (name) {
					return _.findIndex(_type_names, function(type_name) {
						return (type_name == name);
					});
				}
			};
		})(),

		BlankType: (function() {
			var _type_names = ['Text', 'Number', 'Email', 'Url', 'Phone', 'Time', 'Address'];
			var _type_labels = ['文本填充题', '数值填充题', '邮箱题', '链接题', '电话题', '时间题', '地址题'];

			return {
				getLabels: function() {return _type_labels; },

				getName: function (value) { return _type_names[value]; },

				getLabel: function (value) { return _type_labels[value]; },

				getValue: function (name) {
					return _.findIndex(_type_names, function(type_name) {
						return (type_name == name);
					});
				}
			};
		})()
		
	});
	
});