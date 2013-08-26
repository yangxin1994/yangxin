//=require 'ui/widgets/od_autotip'

$(function(){
	//Pagination
	//title:页面名, total:数据总数, c_page:当前显示第几页, link:此页面链接，p_page:一页显示几条数据
	window.setPage = function(title, total, link, c_page, p_page,l){
		var showPage = 4; //页脚处显示4个页码
		//var pageCount = total%p_page==0? total/p_page: Math.ceil(total/p_page); //总共页码数
		var pageCount = total;

		if(pageCount<showPage) showPage = pageCount;
		var firstPage = (c_page >= showPage/2 +1) ? Math.ceil(c_page - showPage/2) :1;
		if((pageCount-firstPage+1)<showPage){
			firstPage-=(showPage-(pageCount-firstPage+1));
		}
		var stopPage = showPage;
		var space = c_page - firstPage;

		var prePage = c_page-1>0?c_page-1:c_page;
		var nextPage = c_page+1<=pageCount?c_page+1:c_page;
		var first = "", last = "", prev = "", next = '';
		var numberLink="";

		//分析有没有其他参数，不能简单地往路径上添加page和per_page参数
		link = link+window.location.search;
		var origin = window.location.origin;
		var pathname = window.location.pathname;
		var page_indexs = $.getSearchIndexs('page');
		if(page_indexs == false) {
			//link上没有参数，可直接 加上
			first = $('<a />').attr('href',link+'?page=1').html('&laquo; 首页');
			last = $('<a />').attr('href',link+'?page='+pageCount).html('尾页 &raquo;');
			prev = $('<a />').attr('href',link+'?page='+prePage).html('&laquo; 上一页');
			next = $('<a />').attr('href',link+'?page='+nextPage).html('下一页 &raquo;');
			numberLink=link+"?page=";
		}
		else if(page_indexs == undefined){
			//如果link上没有page参数，但有其它参数，可直接 接上
			first = $('<a />').attr('href',link+'&page=1').html('&laquo; 首页');
			last = $('<a />').attr('href',link+'&page='+pageCount).html('尾页 &raquo;');
			prev = $('<a />').attr('href',link+'&page='+prePage).html('&laquo; 上一页');
			next = $('<a />').attr('href',link+'&page='+nextPage).html('下一页 &raquo;');
			numberLink=link+"&page=";
		}
		else{
			//如果link上有page参数，找到其相应位置，修改之
			var params =  decodeURI(window.location.search.substring(1));
			var str1 = $.verifyToString(params.substring(0, page_indexs[0]));
			var str2 = $.verifyToString(params.substring(page_indexs[1]+1, params.length));
			var pre_deal_params = str1+"page="+prePage+ str2;
			var next_deal_params = str1+"page="+nextPage+ str2;
			var pre_url = origin + pathname + '?' + pre_deal_params;
			var next_url = origin + pathname + '?' + next_deal_params;
			prev = $('<a />').attr('href',pre_url).html('&laquo; 上一页');
			next = $('<a />').attr('href',next_url).html('下一页 &raquo;');
			first = $('<a />').attr('href',origin + pathname +'?'+str1+'page=1'+str2).html('&laquo; 首页');
			last = $('<a />').attr('href',origin + pathname +'?'+str1+'page='+pageCount+str2).html('尾页 &raquo;');
			numberLink=origin + pathname + '?' + str1+"page=";
		}

		$('.'+title+' .pagination').append(first).append(prev);
		var a=new Array(); var tempPage = firstPage;
		for(var i=0; i<stopPage; i++){
			a[i] = $('<a />').addClass('number').html(tempPage);
			a[i].attr('href',numberLink+tempPage);
			if(i-space==0) a[i].addClass('current');
			$('.'+title+' .pagination').append(a[i]);
			tempPage++;
		};
		$('.'+title+' .pagination').append(next).append(last);
	};

	//切换标签
	window.changeTab = function(tab){//传入要显示的标签 $标题
		tab.parent().siblings().find("a").removeClass('current');
		tab.addClass('current');
		var currentTab = tab.attr('href');
		$(currentTab).siblings().hide();
		$(currentTab).show();
		return false;
	}

	//时间显示处理 time="yyyy-MM-dd hh:mm";
	window.formatTime =  function(time,format){
		var o = {
			"M+" : time.getMonth() + 1,
			"d+" : time.getDate(),
			"h+" : time.getHours(),
			"m+" : time.getMinutes(),
			"s+" : time.getSeconds(),
			"q+" : Math.floor((time.getMonth() + 3) / 3),
			"S" : time.getMilliseconds()
		}
		if (/(y+)/.test(format))
		{
			format = format.replace(RegExp.$1, (time.getFullYear() + "").substr(4- RegExp.$1.length));
		}
		for (var k in o)
		{
			if (new RegExp("(" + k + ")").test(format))
			{
				format = format.replace(RegExp.$1, RegExp.$1.length == 1 ? o[k]: ("00" + o[k]).substr(("" + o[k]).length));
			}
		}
		return format;
	}

	//省略字符串
	window.subStr = function(str,l){
		if(str.length <= l)
			return str;
		else{
			return str.substring(0,l)+'...';
		}
	}

	//获得URL的参数
	window.getUrlVar = function(){
	    var vars = [], hash;
	    var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
	    for(var i = 0; i < hashes.length; i++)
	    {
	      hash = hashes[i].split('=');
	      vars.push(hash[0]);
	      vars[hash[0]] = hash[1];
	    }
	    return vars;
  }

   $.getSearchIndexs = function(key){
		var params =  decodeURI(window.location.search.substring(1));
		if(params == false | params == '') return false;
		var tmp_page_index = params.indexOf(key, 0);
		var page_start_index = undefined;
		while(tmp_page_index >= 0)
		{
			if (params[tmp_page_index-1] == undefined || params[tmp_page_index-1]== '&')
			{
				page_start_index = tmp_page_index;
				break;
			}
			else{
				tmp_page_index = params.indexOf(key, tmp_page_index + key.length);
			}
		}
		var page_end_index = undefined;
		if(page_start_index != undefined){
			var page_end_index  = params.indexOf('&', page_start_index);
			if(page_end_index < 0){
				page_end_index = params.length - 1;
			}else{
				page_end_index = page_end_index - 1;
			}
		}
		if(page_start_index != undefined && page_end_index != undefined){
			var arr = new Array(page_start_index, page_end_index);
			return arr;
		}else{
			return undefined;
		}
	}

	$.verifyToString =  function(key){
		if(key == undefined || key == null ){return "";}
		return key;
	}

	window.getLinkUrl = function(param,value){
		var origin = window.location.origin;
		var pathname = window.location.pathname;
		var param_indexs = $.getSearchIndexs(param);
		var params =  decodeURI(window.location.search.substring(1));
		var str1 = $.verifyToString(params.substring(0, param_indexs[0]));
		var str2 = $.verifyToString(params.substring(param_indexs[1]+1, params.length));

		return origin+pathname+ '?' +str1+param+"="+value+str2;
	}
});
