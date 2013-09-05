
jQuery(function($) {
	var curr_page=window.getUrlVar()['page']==null?1:parseInt(window.getUrlVar()['page']);
	var data_onePage = window.getUrlVar()['per_page']==null?10:parseInt(window.getUrlVar()['per_page']);//后台默认为10条
	
	var mdata = window.messages;//默认获得前十条数据
	var total_page = window.messages_count; //总共页数
	var length=0;
	if(mdata){
		length = mdata.length;
		if(mdata.error_code){
			mdata={};
			total=0;
			alert("您没有管理员权限！");
		}
	}
	

	//myPagination,返回当前页面显示的数据数
	var link = "/admin/messages";

	var content = new Array();
	var receiverList = new Array();
	for(var i = 0; i<length; i++){
		var tr = $('<tr />');

		var td = new Array(7);
		$.each(td,function(j){  
			td[j] = $('<td />');
		});
		
		td[0].html('<input type="checkbox" />');
		
		var title = $('<a />').attr('href','#').html(window.subStr(mdata[i].title,10));				
		td[1].append(title);
		//发送者
		td[2].html(mdata[i].sender_email);
		//消息时间
		var format = window.formatTime(new Date(mdata[i].created_at),'yyyy-MM-dd hh:mm');
		td[3].html(format);
		//接受者
		var flag = mdata[i].receiver_emails.length;
		var receiver;
		switch (flag){
			case 0: receiver = "全部";break;
			case 1: receiver = mdata[i].receiver_emails[0];break;
			default: {
				receiver = mdata[i].receiver_emails[0]+"...";
				//create tip to show receiver eamil
				var showReceiver = '<div class="tip-receiver">';
				for(var k=0; k<mdata[i].receiver_emails.length;k++){
					showReceiver+='<div>'+mdata[i].receiver_emails[k]+'</div>'
				}
				showReceiver+='</div>';
/*				receiverList[i] = $.od.odTip({
					tipId:'MReceiver'+i,
					title:false,
					tipTop:-11,
					tipCorner:"2%",
					tipContent:showReceiver
				});*/
				break;
			}
		}
		td[4].html(receiver);
		//删除按钮
		var del = $('<a />').attr('href','#').html('<img src="../../assets/od-icon/cross.png" alt="Delete" class="del"/>');
		td[5].append(del);
		//存储数据id，不显示
		td[6].html(mdata[i]._id).hide();

		//create tip to show content
		var showContent = '<div class="tip-content"><div class="green-title">标题</div><div class="tip-title">'
			+mdata[i].title+'</div><div class="green-title">内容</div><div class="tip-title">'
			+mdata[i].content+'</div></div>'
/*		content[i]= $.od.odTip({
			tipId:'MContent'+[i],
			title:false,
			tipCorner:"5%",
			tipWidth:390,
			tipLeft:16,
			tipContent:showContent
		});*/

		$.each(td,function(j){  
			tr.append(td[j]);
		});

		$('tbody').append(tr);
	}

	//点击标题,显示内容		
	$('tbody tr').find('td:eq(1)').children().click(function(e){
		e.stopPropagation();
		var i=$(this).parent().parent().index();
		content[i].odTip('show',true,$(this));
	});

	//鼠标经过接收人显示列表
	$('tbody tr').find('td:eq(4)').mouseover(function(e){
		e.stopPropagation();
		var i = $(this).parent().index();
		if(receiverList[i]){
			receiverList[i].odTip('show',true,$(this));
		}
	});

//delete one data
	function delOne(delId,showTip){
		$.deleteJSON(link+'/'+delId + '.json', 
			null,
			function(msg){
				if (msg) {//返回true
					//自动提示删除成功

					if(showTip){
						var noti = $.od.odAutotip({content:'系统消息已成功删除！',style:'success'});
						noti.addClass('notification');
					}	

					console.log('success: delete '+delId);				
				} else {//否则弹出错误信息
					//自动提示删除失败
					if(showTip){
						var noti = $.od.odAutotip({content:'删除失败！',style:'error'});
						noti.addClass('notification');
					}
					console.log('error: delete '+delId);
					return false;
				}
		});
	}
	$('.del').click(function(e){
		e.stopPropagation();
		//delete data from database
		try{
			var delId = $(this).parent().parent().next().html();
			$(this).parentsUntil('tr').parent().remove();
			delOne(delId,true);
		}catch(ex){
			alert("删除失败！");
		}
	});

//delete all data
	$('.deleteAll').click(function(e){
		e.stopPropagation();
			if($('TBODY').find(':checked').length>0){
				var delId = new Array();//记录删除的数据ID
				var arrDelId = '';
				$('TBODY').find(':checked').each(function(i){
					delId[i] = $(this).parent().parent().find('td:last').html();
					$(this).parentsUntil('tr').parent().remove();
					delOne(delId[i],false);
				});
				var noti = $.od.odAutotip({content:'系统消息已成功删除！',style:'success'});
				noti.addClass('notification');
				if(curr_page==total_page){//跳至page=1
					window.location.href=window.getLinkUrl("page","1");
				}
				else
					location.reload(true);
			}
			else{
				var noti = $.od.odAutotip({content:'请勾选您要删除的数据！',style:'success'});
				noti.addClass('notification');			
			}
	});

//check all
	$('thead .check-all').change(function(){
		if(this.checked )
			$('tbody :checkbox').attr('checked','checked');
		else{
			$('tbody :checkbox').removeAttr('checked');
		}
	});

	/******************新建消息****************/
	//点击发布按钮
	$('.error').hide();

	$('.newMessage').click(function(){
		$(this).attr("disabled","disabled");
		var param = {
			title:$('.txt-title').val(),
			content:$('.txt-content').val(),
			receiver:$('.txt-receiver').val()
		};
		if(param.title == ''){
			$('.txt-title').next().show();
			$(this).removeAttr("disabled");
		}
		else if(!correctEmail($('.txt-receiver'))){
			$('.txt-receiver').next().show();
			$('.txt-receiver').next().next().hide();
			$('.txt-title').next().hide();
			$(this).removeAttr("disabled");
		}
		else if(param.content ==''){
			$('.txt-content').prev().show();
			$(this).removeAttr("disabled");
		}
		else {
			$('.txt-title, .txt-receiver').next().hide();
			$('.txt-content').prev().hide();
			//AJAX
			$.postJSON(link+".json",param,function(retval){
				console.log(retval);
				if(retval.success) {
					window.location.href=link;
				} else {
					console.log('error: add message !');
					$(this).removeAttr("disabled");
				}
			});
		}
	});
	function correctEmail(mail){		
		var mail_value=mail.val();
		var comma=mail_value.search(",");
		var flag=true;

		if(comma==-1&&mail_value!=""){//only one or all email
			if(!($.regex.isEmail(mail_value)))
				flag=false;
		}
		else if(mail_value!=""){
			var temp_value=mail_value;
			var last=comma;
			var i=0;
			do{
				var one_mail=temp_value.substr(0,last);
				if(!($.regex.isEmail(one_mail))){
					flag=false;
					break;
				}
				else{
					temp_value=temp_value.substr(last+1);
					last=temp_value.search(",");
				}				
			}while(last!=-1);
			if(!($.regex.isEmail(temp_value)))
				flag=false;

		}

		if( flag ){
			mail.removeClass('error');
			mail.next().hide();   
			mail.next().next().show();
			return true;  
		}else{   
			mail.addClass('error');
			mail.next().show(); 
			mail.next().next().hide();
			return false; 
		}
	}


	$('.txt-receiver').blur(function(){		
		  correctEmail($(this));
	});

});