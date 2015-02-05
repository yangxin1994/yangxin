//=require config/quill
//=require ui/widgets/od_icon_buttons
//=require ui/widgets/od_tip
//=require ui/widgets/od_confirm_tip
//=require ui/widgets/od_autotip
//=require ui/plugins/od_button_text
//=require jquery.smartFloat
//=require jquery-powerFloat-min

$(function(){
    //登录页相关
	if( !('placeholder' in document.createElement('input')) ){   
	  $('input[placeholder],textarea[placeholder]').each(function(){    
	    var that = $(this),    
	    text= that.attr('placeholder');    
	    if(that.val()===""){    
	      that.val(text).addClass('placeholder');    
	    }    
	    that.focus(function(){    
	      if(that.val()===text){    
	        that.val("").removeClass('placeholder');    
	      }    
	    })    
	    .blur(function(){    
	      if(that.val()===""){    
	        that.val(text).addClass('placeholder');    
	      }    
	    })    
	    .closest('form').submit(function(){    
	      if(that.val() === text){    
	        that.val('');    
	      }    
	    });    
	  });    
	};

	$('.user-panel input').focus(function(){
	$('span.notice').remove();
	})
	$('.login-btn').click(function(){
		var email = $.trim($('#login_email').val());
		var pwd   = $.trim($('#login_password').val());
		if(email.length > 0 && pwd.length > 0){
        	$('.login-btn').html('登录中')
        	$('.login-btn').attr('disabled', true).addClass('disabled')
        	$.postJSON('/account/login', {
        	    email_mobile: email,
        	    password: pwd
        	}, function(retval) {
        	    if (retval.success) {
        	        location.href = '/account/after_sign_in' + ($.util.param('ref') ? ('?ref=' + $.util.param('ref')) : '?ref=/travel');
        	    } else {
        	        $('.login-btn').attr('disabled', false).removeClass('disabled')
        	        $('.login-btn').html('登录')
        	        generate_error_message(retval.value['error_code'])
        	    }
        	})
		}
	})

    function generate_error_message(error_type) {
        var err_notice = null
        switch (error_type) {
            case 'error_3':
                err_notice = "<span class='notice'>账户未激活</span>"
                break;
            case 'error_4':
                err_notice = "<span class='notice'>账户不存在</span>"
                break;
            case 'error_11':
                err_notice = "<span class='notice'>密码错误</span>"
                break;
            case 'error_24':
                err_notice = "<span class='notice'>账户未注册</span>"
                break;
        }
        if (error_type == 'error_11') {
            if ($('[name="password"]').next('span.faild').length < 1) {
                $('[name="password"]').after(err_notice);
            }
        } else {
            if ($('[name="email"]').next('span.faild').length < 1) {
                $('[name="email"]').after(err_notice);
            }
        }

    }

    //城市列表页相关
    $('#suffice-finished').on('click', '#suffice', function(event) {
      $('.city-list').toggleClass('finished');
      $('.answer-list').toggleClass('finished');
    });

    $('.answer-list').on('click','.survey',function(event) {
      $(this).parent().siblings('dd').slideToggle(400);
    });

    $('.cities a').click(function(){

        var checked = false;
        var action  = 'prev';
        if($('#suffice:checked').length > 0){
            checked = true
        }
        if($(this).hasClass('next')){
            action = 'next'
        }
        
        var year  = $(this).attr('year')
        var  month = $(this).attr('month')

        $.getJSON('/travel/cities',{
            act:action,
            year: year,
            month: month,
            checked:checked
        },function(retval){
            var list = '';
            $.each(retval.value, function( key, value ) {
                if($.inArray(key,['from','to','year','month','quarter']) < 0 ){
                    list += '<li>\
                       <a href="/travel/cities/' +  key + '?from=' + retval.value['from'] +  '&to=' + retval.value['to']  + '"> \
                        <span class="city-name">' + key  + '</span>\
                        <span class="num"><em class="finished">' + value['finished'] + '</em><em class="suffice">' + value['checked'] + '</em>/' + value['amount'] + '</span>\
                        <span class="progress finished" style="width:' + value['finish_percent'] + '"></span>\
                        <span class="progress suffice" style="width:' + value['check_percent'] + '"></span>\
                        </a>\
                        </li>'
                }
            })

            $('.cur-quarter').text(retval.value['quarter']) 
            $('#quarter a').attr('year',retval.value['year']).attr('month',retval.value['month'])
            if(list.length > 0){
                $('.city-list ul').empty().append(list)    
            }else{
                $('.city-list ul').empty().append('<div class="no-data">没有查到更多数据！</div>')        
            }
            
        })
    })

    $('.interviewers a').click(function(){
        var city    = $('.current_city').text();
        var checked = false;
        var action  = 'prev';
        if($('#suffice:checked').length > 0){
            checked = true
        }
        if($(this).hasClass('next')){
            action = 'next'
        }
        
        var year  = $(this).attr('year')
        var  month = $(this).attr('month')

        $.getJSON('/travel/cities/' + city,{
            act:action,
            year: year,
            month: month,
            checked:checked
        },function(retval){
            var dl = '';
            $.each(retval.value,function(key,value){
                if(value.from){
                    $('.cur-quarter').text(value.quarter);
                    $('.interviewers a').attr('year',value.year).attr('month',value.month);
                }else{
                    var interviewers = '';
                    $.each(value.interviews,function(k,task){                     
                        var amount  = task.quota['rules'][0]['amount']
                        var submit  = task.quota['rules'][0]['submitted_count']
                        var suffice = task.quota['rules'][0]['finished_count']
                        var submit_percent  = submit / amount * 100 + '%';
                        var suffice_percent = suffice / amount * 100 + '%';
                        interviewers += '<li>\
                           <a href="/travel/surveys/' + value['_id'] + '/interviewers/' + task['_id'] + '">\
                             <span class="name"><i class="icon-user mr5"></i>'  + task.nickname   +  '</span>\
                             <span class="progress-bar">\
                                <span class="num"><i class="finished">' +  submit + '</i><i class="suffice">' + suffice + '</i>/' +  amount + '</span>\
                                <span class="progress finished" style="width:' + submit_percent + ';"></span>\
                                <span class="progress suffice" style="width:' + suffice_percent +  ';"></span>\
                             </span>\
                           </a>\
                        </li>'
                    })
                    dl += '<dl>\
                        <dt>\
                            <a class="survey" href="javascript:void(0);">\
                                <i class="icon-file-text-alt mr5"></i>' + value.title + '<span class="num r"><em class="finished">' + value.finish + '</em><em class="suffice">' + value.suffice + '</em> /' + value.amount + '</span>\
                            </a>\
                        </dt>\
                        <dd class="dn">\
                            <ul>' +  interviewers  + '</ul>\
                        </dd>\
                    </dl>';
                }
            })
            if(dl.length > 0){
                $('.answer-list').empty().append(dl)
            }else{
                $('.answer-list').empty().append('<div class="no-data">没有查到更多数据！</div>')
            }
            
        })
    })

    //访问员页面，鼠标在不同的答案之间hover,引起地图marker的变化
    $('li.real-data').hover(function(){
        init($(this));//每次都会重新显示当前的答案的答题地址,并重新标注
    })
    //访问员详细页,点击复选框触发请求
    $('.task_finished').click(function(){
        str = window.location.href.split('&')[0]

        if($('#suffice:checked').length > 0){
            str += '&suffice=true'
        }else{
            str += '&suffice=false'
        }

        window.location.href = str

    })

})
