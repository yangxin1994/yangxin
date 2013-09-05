//=require ui/widgets/od_left_icon_button
//=require ui/widgets/od_popup
//=require ui/widgets/od_progressbar

jQuery(function($) {
	window.survey_filters.splice(0, 0, {name: '所有样本'});
	var filters_size = window.survey_filters.length;
	var mockups_size = window.report_mockups.length;

	/* mockups render */
	for(var n = 0 ; n < mockups_size; n ++) {
		var $wrap = $('<div />');
		$wrap.addClass("rm-wrap");

		var $fbr = $('<div />');
		$fbr.addClass("fix be6 report-title");
		var $tfbbl = $('<h2 />');
		$tfbbl.addClass("title f14 blue b l");
		$tfbbl.text(window.report_mockups[n].title);
		var current_report_id = window.report_mockups[n]["_id"];

		var $mbr = $('<span />');
		$mbr.addClass("manage-btn r");
		var $iie = $('<em title="编辑" />');
		$iie.addClass("icon icon-edit");
		$iie.data("id", report_mockups[n]._id);
		var $iid = $('<em title="删除" />');
		$iid.addClass("icon icon-del");
		$iid.data("id", report_mockups[n]._id);
		var $iis = $('<em title="分享" />');
		$iis.addClass("icon icon-share");
		$iie.appendTo($mbr);$iid.appendTo($mbr);$iis.appendTo($mbr);

		$tfbbl.appendTo($fbr);$mbr.appendTo($fbr);
		$fbr.appendTo($wrap);

		var $fb = $('<div />');
		$fb.addClass("fix bf2");
		$fb.hide();

		var $tfbbt = $('<h2 />');
		$tfbbt.addClass("title f14 blue b pt20");
		$tfbbt.text("分享报告");
		var $la = $('<input type="text" name="link-address"/>');
		$la.addClass("link-address");
		var $ob = $('<button href="#" />');
		$ob.addClass("od-button");
		$ob.text("复制问卷链接");
		var $obd = $('<button href="#" />');
		$obd.addClass("od-button disabled");
		$obd.text("邮件分享");
		$tfbbt.appendTo($fb);$la.appendTo($fb);$la.append(" ");$ob.appendTo($fb);$ob.append(" ");$obd.appendTo($fb);

		var $share = $('<ul />');
		$share.addClass("share");

		var $ligmail = $('<li />');
		$ligmail.addClass("l");
		var $agmail = $('<a href="javascript:void(0);" title="gmail" />');
		$agmail.addClass("icon icon-gmail");
		$agmail.appendTo($ligmail);

		var $lidouban = $('<li />');
		$lidouban.addClass("l");
		var $adouban = $('<a href="javascript:void(0);" title="豆瓣" />');
		$adouban.addClass("icon icon-douban");
		$adouban.appendTo($lidouban);		

		var $lirenren = $('<li />');
		$lirenren.addClass("l");
		var $arenren = $('<a href="javascript:void(0);" title="人人" />');
		$arenren.addClass("icon icon-renren");
		$arenren.appendTo($lirenren);	

		var $lidiandian = $('<li />');
		$lidiandian.addClass("l");
		var $adiandian = $('<a href="javascript:void(0);" title="点点" />');
		$adiandian.addClass("icon icon-diandian");
		$adiandian.appendTo($lidiandian);

		var $lisina = $('<li />');
		$lisina.addClass("l");
		var $asina = $('<a href="javascript:void(0);" title="新浪微博" />');
		$asina.addClass("icon icon-sina");
		$asina.appendTo($lisina);

		$ligmail.appendTo($share);$lidouban.appendTo($share);$lirenren.appendTo($share);$lidiandian.appendTo($share);$lisina.appendTo($share);
		$share.appendTo($fb);
		$fb.appendTo($wrap);

		var $dl = $('<dl />');
		$dl.addClass("filter-list");
		$dl.appendTo($wrap);

		$wrap.appendTo(".edit-panel");
	};			

	// var $dt = $('<dt />');
	// $dt.addClass("g9");
	// $dt.text("（不包含被筛选掉的样本）");
	// $dt.appendTo(".filter-list");
	/* mockups render end */

	/* filters render */		
	for(var i = 0; i < filters_size; i ++) {
			var $dd = $('<dd />');
			$dd.addClass("f14");
			var $span = $('<span />');
			$span.addClass("l");
			$span.text(window.survey_filters[i].name);
			$span.appendTo($dd);

			for(var j = 1; j < 4; j ++) {
				var $ul = $('<ul />');
				if(j == 1)
					$ul.addClass("r")
				else
					$ul.addClass("r mr10");

				var $liw = $('<li />');
				$liw.addClass("r mr10");
				var $aw = $('<a href="javascript:void(0)" />');
				$aw.addClass("office word" + j);
				$aw.appendTo($liw);
				$liw.appendTo($ul);

				var $lir = $('<li />');
				$lir.addClass("r mr10");
				var $ar = $('<a href="javascript:void(0)" />');
				$ar.addClass("office reader" + j);
				$ar.appendTo($lir);
				$lir.appendTo($ul);

				var $lie = $('<li />');
				$lie.addClass("r mr10");
				var $ae = $('<a href="javascript:void(0);" />');
				$ae.addClass("office excel" + j);
				$ae.appendTo($lie);
				$lie.appendTo($ul);

				$ul.appendTo($dd);		
			};

			//TODO
			function exportResult(report_id, filter_index) {
				var pop_con = $('<div style="text-align:center; padding-top: 10px;"/>');
				var export_pb = $.od.odProgressbar({width: 160}).appendTo(pop_con);
				var waiting_pop = $.od.odPopup({ type:null, title: '正在导出到报告 ...', content: pop_con, closeButton: false });
				//TODO: export to excel
				$.getJSON('/questionaires/' + window.survey_id + '/report_mockups/' + report_id + '/report.json', {
					filter_index: filter_index
				}, function(retval) {
					console.log(retval);
					if(retval.success) {
						// check export progress
						function _getExportResult(job_id) {
							$.getJSON('/jobs/' + job_id + '.json', {}, function(retval) {
								if(retval.success) {
									var value = retval.value;
									console.log(retval.value);
									export_pb.odProgressbar('option', 'value', value.progress);
									if(value.progress >= 1) {
										if(waiting_pop) waiting_pop.odPopup('destroy');
										var url = 'http://export.oopsdata.com/public/' + retval.value.result.file_name;
										var info_con = $('<div >导出完成，浏览器将自动下载结果，您也可以 <a target="blank">点击此处</a> 手动下载。</div>');
										$('a', info_con).attr('href', url);
										$.od.odPopup({ title: '导出完成', content: info_con });
										window.open(url);
										return;
									}
								}
								setTimeout(_getExportResult(job_id), 500);
							});
						};
						_getExportResult(retval.value);
					} else {
						if(waiting_pop) waiting_pop.odPopup('destroy');
						$.od.odPopup({ title: '导出失败', content: '导出失败，请重试。' });
					}
				});
			};
			console.log(current_report_id);
			$('a.office', $dd).click((function(r, f) {
				return function() {
					exportResult(r, f);
				}
			})(current_report_id, i-1));

			$dd.appendTo(".filter-list");
	};
	/* filters render end */	

	$(".icon-share").click(function() {
		$(this).parent().parent().next().slideToggle("slow");
	});

	$(".icon-edit").click(function() {
		window.location = '/questionaires/' +	window.survey_id + '/report_mockups/' + $(this).data("id");
	});

	$(".icon-del").click(function() {
		var $rm_wrap = $(this).parent().parent().parent();
		$.deleteJSON(
			'/questionaires/' + window.survey_id + '/report_mockups/' + $(this).data("id"),
			function(retval) {
				if(retval.success) {
					$rm_wrap.slideUp("slow", function() {$rm_wrap.remove();});
				} else {
					$.od.odPopup({title: "提示", content: "删除出错 :(.<br/>错误代码：" + retval.value.error_code});
				}
			}
		);
	});

	var libtn = $.od.odLeftIconButton({text: '添加调研报告', icon: 'add', width: 105});
	libtn.appendTo('#add_report');
	libtn.click(function() {
		var reportMockup = {
			_id: null,
			survey_id: window.survey_id,
			title: "",
			subtitle: "",
			header: "",
			footer: "",
			author: "",
			components: []
		};
		$.postJSON(
			'/questionaires/' + window.survey_id + '/report_mockups',
			{
				report_mockup: reportMockup
			},
			function(retval) {
				if(retval.success) {
					window.location = '/questionaires/' +	window.survey_id + '/report_mockups/' + retval.value._id;
				} else {
					$.od.odPopup({title: "提示", content: "添加出错 :(.<br/>错误代码：" + retval.value.error_code});
				}
			}
		);		
	});

	$(".icon-gmail").click(function() {
		gmailShare($(this).parent().parent().parent().find("input").val());
	});
	$(".icon-douban").click(function() {
		doubanShare($(this).parent().parent().parent().find("input").val());
	});
	$(".icon-renren").click(function() {
		renrenShare($(this).parent().parent().parent().find("input").val());
	});
	$(".icon-diandian").click(function() {
		diandianShare($(this).parent().parent().parent().find("input").val());
	});
	$(".icon-sina").click(function() {
		sinaWeiboShare($(this).parent().parent().parent().find("input").val());
	});

	function sinaWeiboShare(address) {
		var param = {
	    	url: address,
	    	appkey:'',			/**申请的appkey,显示分享来源(可选)*/
	    	title:'分享问卷链接：', 			/**分享的文字内容(可选，默认为所在页面的title)*/
	    	pic:'', 			/**分享图片的路径(可选)*/
	    	ralateUid:'', 		/**关联用户的UID，分享微博会@该用户(可选)*/
			language:'zh_cn' 	/**设置语言，zh_cn|zh_tw(可选)*/		
		};
		var temp = [];
		for( var p in param ){
			temp.push(p + '=' + encodeURIComponent( param[p] || '' ) )
		};
		var hyperlink = "http://service.weibo.com/share/share.php?" + temp.join('&');
		window.open(hyperlink);
	};

	function diandianShare(address) {
		var param = {
			ti: '分享问卷链接：',
			lo: address,
			type: 'link'
		};
		var temp = [];
		for( var p in param ){
			temp.push(p + '=' + encodeURIComponent( param[p] || '' ) )
		};
		var hyperlink = "http://www.diandian.com/share?" + temp.join('&');
		window.open(hyperlink);		
	};

	function renrenShare(address) {
		var param = {
			resourceUrl : address,						//分享的资源Url
			srcUrl : address,		//分享的资源来源Url,默认为header中的Referer,如果分享失败可以调整此值为resourceUrl试试
			pic : '',									//分享的主题图片Url
			title : '分享问卷链接：',					//分享的标题
			description : ''							//分享的详细描述
		};
		var temp = [];
		for( var p in param ){
			temp.push(p + '=' + encodeURIComponent( param[p] || '' ) )
		};
		var hyperlink = "http://widget.renren.com/dialog/share?" + temp.join('&');
		window.open(hyperlink);		
	};

	function doubanShare(address) {
		var param = {
			image: '',
			href: address,
			name: '分享问卷链接：'
		};
		var temp = [];
		for( var p in param ){
			temp.push(p + '=' + encodeURIComponent( param[p] || '' ) )
		};
		var hyperlink = "http://shuo.douban.com/!service/share?" + temp.join('&');
		window.open(hyperlink);		
	};	

	function tencentWeiboShare(address) {
		var param = {
			title: '分享问卷链接：',
			url: address,
			appkey: '',
			site: '',
			pic: ''
		};
		var temp = [];
		for( var p in param ){
			temp.push(p + '=' + encodeURIComponent( param[p] || '' ) )
		};
		var hyperlink = "http://share.v.t.qq.com/index.php?c=share&a=index&" + temp.join('&');
		window.open(hyperlink);		
	};

	function qqSpaceShare(address) {
		var param = {
			url:address,
			desc:'',					/*默认分享理由(可选)*/
			summary:'',					/*分享摘要(可选)*/
			title:'分享问卷链接：',		/*分享标题(可选)*/
			site:'',					/*分享来源 如：腾讯网(可选)*/
			pics:'', 					/*分享图片的路径(可选)*/
		};
		var temp = [];
		for( var p in param ){
			temp.push(p + '=' + encodeURIComponent( param[p] || '' ) )
		};
		var hyperlink = "http://sns.qzone.qq.com/cgi-bin/qzshare/cgi_qzshare_onekey?" + temp.join('&');
		window.open(hyperlink);		
	};

	function fetionShare(address) {
		var param = {
			Source: '',
			Title: '分享问卷链接：',
			Url: address
		};
		var temp = [];
		for( var p in param ){
			temp.push(p + '=' + encodeURIComponent( param[p] || '' ) )
		};
		var hyperlink = "http://i2.feixin.10086.cn/app/api/share?" + temp.join('&');
		window.open(hyperlink);		
	};

	function kaixinShare(address) {
		var param = {
			content: '分享问卷链接：',
			url: address,
			starid: '',
			aid: '',
			style: 11,
			pic: ''
		};
		var temp = [];
		for( var p in param ){
			temp.push(p + '=' + encodeURIComponent( param[p] || '' ) )
		};
		var hyperlink = "http://www.kaixin001.com/rest/records.php?" + temp.join('&');
		window.open(hyperlink);		
	};

	function gmailShare(address) {
		var param = {
			su: '分享问卷链接：',
			body: address
		};
		var temp = [];
		for( var p in param ){
			temp.push(p + '=' + encodeURIComponent( param[p] || '' ) )
		};
		var hyperlink = "https://mail.google.com/mail/?ui=2&view=cm&fs=1&tf=1&" + temp.join('&');
		window.open(hyperlink);		
	};			

});