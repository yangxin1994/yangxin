$(function() {

    $('.form  input').focus(function() {
        clear_notice($(this))
    })

    $('.login_btn').click(function() {
        var obj = $('[name="username"]');
        var account = obj.val();
        var pass = $('[name="password"]').val();
        var signed_in = $('.rember_me').is(':checked') ? true : false
        var thid_id = null
        if (account.length < 1) {
            obj.addClass('error')
        } else if (pass.length < 1) {
            $('[name="password"]').addClass('error')
        } else {
            login(obj, account, pass, signed_in)
        }


    })

    //相应回车提交表单事件 

    function submit_form() {
        $('.login_btn').click();
    }
    $('input[name="password"]').odEnter({
        enter: submit_form
    });

    function login(obj, account, pass, signed_in, thid_id) {
        $('.login_btn').html('登录中')
        $('.login_btn').attr('disabled', true).addClass('disabled')
        $.postJSON('/account/login.json', {
            email_mobile: account,
            password: pass,
            third_party_user_id: thid_id,
            permanent_signed_in: signed_in
        }, function(retval) {
            if (retval.success) {
                location.href = '/account/after_sign_in' + ($.util.param('ref') ? ('?ref=' + $.util.param('ref')) : '');
            } else {
                $('.login_btn').attr('disabled', false).removeClass('disabled')
                $('.login_btn').html('登录')
                generate_error_message(retval.value['error_code'])
            }
        })
    }


    function generate_error_message(error_type) {
        var err_notice = null
        switch (error_type) {
            case 'error_3':
                err_notice = "<span class='faild'></span><span class='notice'>账户未激活,<a href='/account/sign_up'>立即激活</a></span>"
                break;
            case 'error_4':
                err_notice = "<span class='faild'></span><span class='notice'>账户不存在 ,<a href='/account/sign_up'>立即注册</a></span>"
                break;
            case 'error_11':
                err_notice = "<span class='faild'></span><span class='notice'>密码错误</span>"
                break;
            case 'error_24':
                err_notice = "<span class='faild'></span><span class='notice'>账户未激活,您可以<a href='/account/sign_up'>重新激活</a></span>"
                break;
        }
        if (error_type == 'error_11') {
            if ($('[name="password"]').next('span.faild').length < 1) {
                $('[name="password"]').after(err_notice);
            }
        } else {
            if ($('[name="username"]').next('span.faild').length < 1) {
                $('[name="username"]').after(err_notice);
            }
        }

    }

    function clear_notice(obj) {
        obj.removeClass('error')
        obj.next('span.faild').remove();
        obj.next('span.notice').remove();
        obj.next('span.success').remove();
    }

})