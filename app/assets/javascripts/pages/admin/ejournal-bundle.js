//=require jquery
//=require jquery.jeditable.mini
//=require utility/ajax
//=require jquery.scrollTo

jQuery(function($) {
	var ejournal = window.ejournal;
	if(!ejournal) {
		alert("不存在该电子杂志");
		window.location = '/admin/ejournals';
		return;
	};
	var mode = window.mode;
	var column_MAX = '0';
	var post_MAX = 0;
	render();

	$("#cancel").click(function() {
		$(this).prop("disabled", true);
		$.deleteJSON(
			window.location.href + '/cancel',
			{},
			function(retval) {
				if(retval.success) {
					alert("取消成功");
					window.location = '/admin/ejournals';
				} else {
					alert("取消失败(;.错误代码：" + retval.value.error_code);
					window.location.reload();
				}
			}
		)
	});
	$("#send").click(function() {
		var send = confirm("是否开始向订阅者群发电子杂志？请确保电子杂志内容符合预期。点击确定开始发送，点击取消重新检查。");
		if(send) {
			$(this).prop("disabled", true);
			$('.showInEdit').remove();
			for(var n in ejournal["content"]) {
				var post = ejournal["content"][n];
				var $post = $("#post" + post["number"]);
				$(".title a", $post).attr("href", post["url"]);
			};
			$(".replace-with-i").replaceWith('<i class="img-r" style="display:none;" />');
			var content = $(".content")[0].outerHTML;
			$.postJSON(
				window.location.href + '/deliver',
				{
					content: content
				},
				function(retval) {
					if(retval.success) {
						alert("发送已处理");
						window.location = '/admin/ejournals';
					} else {
						alert("保存失败(;.错误代码：" + retval.value.error_code);
						window.location.reload();
					}
				}
			)			
		};
	});
	$("#save").click(function() {
		console.log(ejournal);
		$(this).prop("disabled", true);
		$.postJSON(
			'/admin/ejournals',
			{
				ejournal: ejournal
			},
			function(retval) {
				if(retval.success) {
					alert("保存成功");
					window.location = '/admin/ejournals/' + retval.value["_id"];
				} else {
					$(this).prop("disabled", false);
					alert("保存失败(;.错误代码：" + retval.value.error_code);
				}
			}
		)
	});
	$("#update").click(function() {
		console.log(ejournal);
		$(this).prop("disabled", true);
		$.putJSON(
			window.location.href,
			{
				ejournal: ejournal
			},
			function(retval) {
				if(retval.success) {
					alert("更新成功");
					window.location.reload();
				} else {
					$(this).prop("disabled", false);
					alert("更新失败(;.错误代码：" + retval.value.error_code);
				}
			}
		)
	});
	$("#delete").click(function() {
		$(this).prop("disabled", true);
		$.deleteJSON(
			window.location.href,
			{},
			function(retval) {
				if(retval.success) {
					alert("删除成功");
					window.location = '/admin/ejournals';
				} else {
					$(this).prop("disabled", false);
					alert("删除失败(;.错误代码：" + retval.value.error_code);
				}
			}
		)
	});
	$("#test").click(function(){
		var test_e = prompt("请输入测试邮箱,多个邮箱请用逗号分隔","");
		if(test_e != null && test_e != "") {
			var emails = test_e.split(/[,，]/);
			for(var m = 0; m < emails.length; m ++) {
				if(!(/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(emails[m].replace(/\s/g, "")))) {
					alert("请输入正确邮箱");
					return;
				}
			};

			$(this).prop("disabled", true);
			$('.showInEdit').remove();
			for(var n in ejournal["content"]) {
				var post = ejournal["content"][n];
				var $post = $("#post" + post["number"]);
				$(".title a", $post).attr("href", post["url"]);
			};
			$(".replace-with-i").replaceWith('<i class="img-r" style="display:none;" />');
			var content = $(".content")[0].outerHTML;
			$.post(window.location.href + '/test',
				{
					email: test_e,
					content: content
				},
				function(retval){
				if(retval.success) {
					alert("发送已处理");
					window.location = '/admin/ejournals';
				} else {
					alert("发送失败(;.错误代码：" + retval.value.error_code);
					window.location.reload();
				}
			});
		}
	});
	$("#return").click(function() {
		$(this).prop("disabled", true);
		window.location = '/admin/ejournals';
	});
	$("#preview").click(function() {
		previewMode();
		$.scrollTo(0, 800);
	});
	$("#reedit").click(function() {
		editMode();
		$.scrollTo(0, 800);
	});
	$("#etitle").blur(function() {
		ejournal["title"] = $(this).val();
	});
	$("#addColumn").click(function() {
		var new_index = String(Number(column_MAX) + 1);
		column_MAX = new_index;
		ejournal["column"][new_index] = "点击修改栏目名称";
		var $da = $('<div />');
		$da.data("index", new_index);
		$da.addClass("article").attr("id", "column" + new_index).insertBefore("#article-end");
		var $ht = $('<h3 />');
		$ht.addClass("editInput column").html(ejournal["column"][new_index]).appendTo($da);
		var $ba = $('<button />').addClass("showInEdit od-button addPost").text("添加文章").appendTo($da);
		var $bd = $('<button />').addClass("showInEdit od-button deleteColumn").text("删除栏目").appendTo($da);
		var post = {
			number: post_MAX + 1,
			caption: "点击修改标题",
			time: "2013.01.01",
			url: "",
			right: true,
			abstract: "点击修改文字摘要",
			image_url: "",
			column_id: new_index
		};
		ejournal["content"].push(post);
		addArticle(post);
		editMode();
	});
	$(".content").delegate(".deleteColumn", "click", function() {
		var index = $(this).parent().data("index");
		delete ejournal["column"][index];
		for(var i in ejournal["content"]) {
			if(ejournal["content"][i]["column_id"] == index)
				ejournal["content"].splice(i, 1);
		};
		$(this).parent().remove();
	});
	$(".content").delegate(".addPost", "click", function() {
		var index = $(this).parent().data("index");
		var post = {
			number: post_MAX + 1,
			caption: "点击修改标题",
			time: "2013.01.01",
			url: "",
			right: true,
			abstract: "点击修改文字摘要",
			image_url: "",
			column_id: index
		};
		ejournal["content"].push(post);
		if(index != '1')
			addArticle(post)
		else
			addProduct(post);
		editMode();
	});
	$(".content").delegate(".deletePost", "click", function() {
		var number = $(this).parent().data("number");
		for(var n in ejournal["content"]) {
			if(ejournal["content"][n]["number"] == number)
				ejournal["content"].splice(n, 1);
		};
		$(this).parent().remove();
	});
	$(".content").delegate(".post-url", "blur", function() {
		var number = $(this).parent().parent().data("number");
		for(var n in ejournal["content"]) {
			if(ejournal["content"][n]["number"] == number)
				ejournal["content"][n]["url"] = $(this).val();
		}
	});
	$(".content").delegate(".post-image", "blur", function() {
		var $post = $(this).parent().parent();
		var number = $post.data("number");
		for(var n in ejournal["content"]) {
			if(ejournal["content"][n]["number"] == number) {
				ejournal["content"][n]["image_url"] = $(this).val();
				$("img", $post).attr("src", $(this).val());
				if($(this).val() != "")
					$("img", $post).show()
				else
					$("img", $post).hide();
			}
		}
	});
	$(".content").delegate(".post-right", "click", function() {
		var $post = $(this).parent().parent();
		var number = $post.data("number");
		for(var n in ejournal["content"]) {
			if(ejournal["content"][n]["number"] == number)
				ejournal["content"][n]["right"] = $(this).prop("checked");
		}
		if($(this).prop("checked"))
			$("img", $post).removeClass("img-l").addClass("img-r")
		else
			$("img", $post).removeClass("img-r").addClass("img-l");
	});


	function editMode() {
		$(".showInEdit").show();
		$("#reedit").hide();
		$("#preview").show();
		$("#update").show();
		$("#send").hide();
		$("#od-test").hide();

		$('.editInput').editable(function(value, settings) {
			if($(this).hasClass("column")) {
				var index = $(this).parent().data("index");
				ejournal["column"][index] = value;
				return value;
			} else if($(this).hasClass("caption")) {
				var number = $(this).parent().parent().data("number");
				for(var n in ejournal["content"]) {
					if(ejournal["content"][n]["number"] == number)
						ejournal["content"][n]["caption"] = value;
				};
				return value;
			} else if($(this).hasClass("article-time")) {
				var number = $(this).parent().data("number");
				var reg = /^[0-9]{4}.[0-9]{2}.[0-9]{2}$/;
				if(!reg.test(value)) {
					alert("请输入正确的日期");
					return "2013.01.01";
				} else {
					for(var n in ejournal["content"]) {
						if(ejournal["content"][n]["number"] == number)
							ejournal["content"][n]["time"] = value;
					};
					return value;
				};
			} else if($(this).hasClass("product-time")) {
				var number = $(this).parent().parent().data("number");
				var reg1 = /^[0-9]{4}$/;
				var reg2 = /^[0-9]{2}$/;
				var $date = $(this).parent();
				var year = $(".year", $date).text();
				var month = $(".month", $date).text();
				var day = $(".day", $date).text();
				if($(this).hasClass("month") || $(this).hasClass("day")) {
					if(!reg2.test(value)) {
						alert("请输入正确的日期");
						return "01";
					} else {
						if($(this).hasClass("month"))
							month = value
						else
							day = value;
						for(var n in ejournal["content"]) {
							if(ejournal["content"][n]["number"] == number)
								ejournal["content"][n]["time"] = year + "." + month + "." + day;
						};
						console.log(year + "." + month + "." + day);
						return value;
					}
				} else if($(this).hasClass("year")) {
					if(!reg1.test(value)) {
						alert("请输入正确的年份");
						return "2013";
					} else {
						year = value;
						for(var n in ejournal["content"]) {
							if(ejournal["content"][n]["number"] == number)
								ejournal["content"][n]["time"] = year + "." + month + "." + day;
						};
						console.log(year + "." + month + "." + day);
						return value;
					}
				}
			} else {
				console.log(this);
				return value;
			};
		}, {
			tooltip: "点击修改",
			onblur: "submit"
		});

		$('.editArea').editable(function(value, settings) {
			if($(this).hasClass("caption")) {
				var number = $(this).parent().parent().data("number");
				for(var n in ejournal["content"]) {
					if(ejournal["content"][n]["number"] == number)
						ejournal["content"][n]["caption"] = value;
				};
				return value;
			} else if($(this).hasClass("abstract")) {
				var number = $(this).parent().parent().data("number");
				for(var n in ejournal["content"]) {
					if(ejournal["content"][n]["number"] == number)
						ejournal["content"][n]["abstract"] = value;
				};
				return value;
			} else {
				console.log(this);
				return value;
			};
		}, {
			tooltip: "点击修改",
			type: "textarea",
			onblur: "submit"
		});
	};

	function previewMode() {
		$(".showInEdit").hide();
		$("#preview").hide();
		$("#reedit").show();
		$(".editInput").unbind();
		$(".editArea").unbind();
	};

	function render() {
		$("#etitle").val(ejournal["title"]);
		for(var i in ejournal["column"]) {
			if(Number(column_MAX) < Number(i))
				column_MAX = i;
			var $da = $('<div />');
			$da.data("index", i);
			$da.attr("id", "column" + i).insertBefore("#article-end");
			if(i != '1')
				$da.addClass("article")
			else
				$da.addClass("product-news fix");
			if(i == '0' || i == '1') {
				$da.css("background", "#F5F5F5");
			};
			var $ht = $('<h3 />');
			$ht.addClass("editInput column").html(ejournal["column"][i]).appendTo($da);
			var $ba = $('<button />').addClass("showInEdit od-button addPost").text("添加文章").appendTo($da);
			if(i != '0' && i != '1')
				var $bd = $('<button />').addClass("showInEdit od-button deleteColumn").text("删除栏目").appendTo($da);
		};
		for(var j = 0; j < ejournal["content"].length; j ++) {
			var p = ejournal["content"][j];
			if(p["column_id"] != '1')
				addArticle(p)
			else
				addProduct(p);
		};
		if(mode == 'new')
			editMode()
		else if(mode == 'show') {
			previewMode();
			switch(ejournal["status"]) {
				case 0:
				case -2:
					$("#send").text("发送");
					break;
				case 1:
					$("#send").text("再次发送");
					break;
				case -1:
					$("#send").hide();
					$("#cancel").show();
					break;
			}
		}
	};

	function addArticle(post) {
		if(post_MAX < post["number"])
			post_MAX = post["number"];
		var $article = $("#column" + post["column_id"]);
		var $at = $('<div />').addClass("article-txt").attr("id", "post" + post["number"]).appendTo($article);
		$at.data("number", post["number"]);
		var $h = $('<h2 />').addClass("title").appendTo($at);
		var $a = $('<a href="javascript:void(0);" />').addClass("editInput caption").html(post["caption"]).appendTo($h);
		var $sd = $('<span />').addClass("date editInput article-time").html(post["time"]).appendTo($at);
		var $ll = $('<label />').addClass("showInEdit").text("文章链接：").appendTo($at);
		$il = $('<input type="text" />').addClass("post-url").val(post["url"]).appendTo($ll);
		var $li = $('<label />').addClass("showInEdit").text("图片源：").appendTo($at);
		$ii = $('<input type="text" />').addClass("post-image").val(post["image_url"]).appendTo($li);
		var $lp = $('<label />').addClass("showInEdit").text("图片居右").appendTo($at);
		var $ip = $('<input type="checkbox" />').addClass("post-right").prop("checked", post["right"]).prependTo($lp);
		var $del = $('<button />').addClass("showInEdit od-button deletePost").text("删除文章").appendTo($at);
		var $p = $('<p />').addClass("fix").appendTo($at);
		var $img = $('<img alt="" />').attr("src", post["image_url"]).appendTo($p);
		if(post["image_url"] == "") {
			$img.addClass("replace-with-i");
			$img.css("display", "none");
		};
		if(post["right"]) {
			$ip.prop("checked", true);
			$img.addClass("img-r");
		} else {
			$ip.prop("checked", false);
			$img.addClass("img-l");
		};
		var $span = $('<span />').addClass("editArea abstract").html(post["abstract"]).appendTo($p);
	};
	function addProduct(post) {
		if(post_MAX < post["number"])
			post_MAX = post["number"];
		var $article = $("#column" + post["column_id"]);
		var $at = $('<div />').addClass("product-news-txt").attr("id", "post" + post["number"]).appendTo($article);
		$at.data("number", post["number"]);

		var $sd = $('<span />').addClass("product-news-date").appendTo($at);
		var date = post["time"].split(".");
		var $mo = $('<span />').addClass("month editInput product-time").text(date[1]).appendTo($sd);
		var $da = $('<span />').addClass("day editInput product-time").text(date[2]).appendTo($sd);
		var $ye = $('<span />').addClass("year editInput product-time").text(date[0]).appendTo($sd);
		var $pd = $('<div />').addClass("article-txt l").css("width", "530px").appendTo($at);
		$pd.data("number", post["number"]);
		var $img = $('<img alt="" />').addClass("img-r").attr("src", post["image_url"]).appendTo($pd);
		if(post["image_url"] == "") {
			$img.addClass("replace-with-i");
			$img.css("display", "none");
		};		
		var $h = $('<h3 />').addClass("title").appendTo($pd);
		var $a = $('<a href="javascript:void(0);" />').addClass("editArea caption").html(post["caption"]).appendTo($h);
		var $pa = $('<p />').addClass("editArea abstract").html(post["abstract"]).appendTo($pd);
		var $cl = $('<div style="clear:both;" />').appendTo($at);
		var $ll = $('<label />').addClass("showInEdit").text("文章链接：").appendTo($at);
		$il = $('<input type="text" />').addClass("post-url").val(post["url"]).appendTo($ll);
		var $li = $('<label />').addClass("showInEdit").text("图片源：").appendTo($at);
		$ii = $('<input type="text" />').addClass("post-image").val(post["image_url"]).appendTo($li);
		var $del = $('<button />').addClass("showInEdit od-button deletePost").text("删除文章").appendTo($at);
	}
});