/* ================================
 * Provide regex related methods
 * ================================ */
(function($){

	$.regex = $.regex || {};

	/* Check string
	 * =============================== */
	$.extend($.regex, {
		isEmail: function(email) {
			return (/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(email));
		},
		isPhone: function(phone) {
			return /^((\d{11})|(\d{3}-\d{8})|(\d{4}-\d{7})|(\d{3}-\d{4}-\d{4}))$/.test(phone);
		},
		isMobile: function(mobile) {
			return /^0?(13\d|15[012356789]|18[0236789]|14[57])-?\d{3}-?\d{1}-?\d{4}$/.test(mobile);
		},
		isIDCard:function(idcard){
			return /^[1-9]\d{5}[1-9]\d{3}((0\d)|(1[0-2]))(([0|1|2]\d)|3[0-1])\d{3}(\d|(x|X))$/.test(idcard);
		},
		isPostcode: function(postcode) {
			return /\d{6}/.test(postcode);
		},
		isUrl: function(url) {
			if(!url) return false;
			var prefix = url.split('?')[0].split('#')[0];
			var strRegex = "^((https|http|ftp|rtsp|mms)?://)"
				+ "?(([0-9a-z_!~*'().&=+$%-]+: )?[0-9a-z_!~*'().&=+$%-]+@)?" //ftp的user@
				+ "(([0-9]{1,3}\.){3}[0-9]{1,3}" // IP形式的URL- 199.194.52.184
				+ "|" // 允许IP和DOMAIN（域名）
				+ "([0-9a-z_!~*'()-]+\.)*" // 域名- www.
				+ "([0-9a-z][0-9a-z-]{0,61})?[0-9a-z]\." // 二级域名
				+ "[a-z]{2,6})" // first level domain- .com or .museum
				+ "(:[0-9]{1,4})?" // 端口- :80
				+ "((/?)|" // a slash isn't required if there is no file name
				+ "(/[0-9a-z_!~*'().;?:@&=+$,%#-]+)+/?)$";
			var re=new RegExp(strRegex);
			return re.test(prefix);
		}
	});

	// console.log($.regex.isEmail() == false);
	// console.log($.regex.isEmail(null) == false);
	// console.log($.regex.isEmail('') == false);
	// console.log($.regex.isPhone() == false);
	// console.log($.regex.isPhone(null) == false);
	// console.log($.regex.isPhone('') == false);
	// console.log($.regex.isMobile() == false);
	// console.log($.regex.isMobile(null) == false);
	// console.log($.regex.isMobile('') == false);
	// console.log($.regex.isPhone('06634322930'));
	// console.log($.regex.isPhone('0661-3928239'));
	// console.log($.regex.isPhone('066-13928939'));
	// console.log($.regex.isPhone('066-1392-2939'));
	// console.log($.regex.isMobile('013298473478'));
	// console.log($.regex.isMobile('132-98473478'));
	// console.log($.regex.isMobile('132-9847-3478'));
	// console.log($.regex.isMobile('132-984-73478'));
	// console.log($.regex.isUrl('baidu.com'));
	// console.log($.regex.isUrl('www.baidu.com'));
	// console.log($.regex.isUrl('http://baidu.com'));
	// console.log($.regex.isUrl('http://www.baidu.com'));
	// console.log($.regex.isUrl('https://www.baidu.com'));
	// console.log($.regex.isUrl('ftp://www.baidu.com'));

})(jQuery);