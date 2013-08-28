jQuery(function($) {

    // ******************
    // Loading detail page

    $(".fancybox").click(function(){
        // loading gif
        $('.loading-div').remove();
        $($(this).attr('href')+' .ajax-content').empty();
        $($(this).attr('href')+' .ajax-content').after('<div class="loading-div" style="position: relative; top: 10px; left: 320px; width: 40px; display: inline-block;">'+
            '<img class="loading" src="/assets/od-icon/loading.gif"/></div>')

        var oid = $(this).attr('name');
        // console.log('loading oid: '+oid);

        // Is login?
        $.getJSON('/users/order_detail/'+oid+'.json', function(data){})

        var _this = $(this);

        $.ajax({
            type: "GET",
            url: '/users/order_detail/'+oid,
            beforeSend: function(xhr){
                xhr.setRequestHeader("OJAX",true);
            }
        }).done(function(data){
            $('.loading-div').remove();
            $(_this.attr('href')+' .ajax-content').html(data);
            $.fancybox.update();
        }).fail(function() { 
            $('.loading-div').remove();
            $(_this.attr('href')+' .ajax-content').html('<div style="position: relative; top: 10px; left: 320px; width: 80px; display: inline-block;">'+
                        '<span class="c-red">请求失败！</span></div>');
        })
    });

});