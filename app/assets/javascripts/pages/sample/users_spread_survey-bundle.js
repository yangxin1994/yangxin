jQuery(function($) {

    // ******************
    //  spread survey detail 

    $(".fancybox").click(function(){
        // loading gif
        $('.loading-div').remove();
        $('#spread-detail .spread-users').empty().append('<div class="loading-div" style="position: relative; top: 10px; left: 320px; width: 40px; display: inline-block;">'+
                    '<img class="loading" src="/assets/od-icon/loading.gif"/></div>');

        var sid = $(this).attr('name');
        // console.log('loading sid: '+sid);

        $('#spread-detail tbody tr').attr('name', sid);
        $('#spread-detail tbody tr td:eq(1)').html($('tbody tr#sid-'+sid+' td:eq(0)').html());
        $('#spread-detail tbody tr td:eq(2)').html($('tbody tr#sid-'+sid+' td:eq(1) a').html());
        $('#spread-detail tbody tr td:eq(3)').html($('tbody tr#sid-'+sid+' td:eq(5)').html());
        $('#spread-detail tbody tr td:eq(6)').html($('tbody tr#sid-'+sid+' td:eq(4)').html());

        // spread users nubmer
        $.ajax({
            type: "GET",
            url: '/users/spread_counter/'+sid+'.json'
        }).done(function(data){
            $('#spread-detail tbody tr td:eq(4)').html(data.value.total_answer_number+'人（'+data.value.editting_answer_number+'人正在答题）');
            $('#spread-detail tbody tr td:eq(5)').html(data.value.finished_answer_number+'人');
        })

        // init survey info
        // $('#spread-detail tbody tr td:eq(1)').html($('tbody tr#sid-'+sid+' td:eq(0)').html());
        // ajax request spreaded-users list
        $.ajax({
            type: "GET",
            url: '/users/survey_detail/'+sid,
            beforeSend: function(xhr){
                xhr.setRequestHeader("OJAX",true);
            }
        }).done(function(data){
            $('#spread-detail .spread-users').empty().append(data);
            $.fancybox.update();
        }).fail(function() { 
            $('#spread-detail .spread-users').empty().append('<div style="position: relative; top: 10px; left: 320px; width: 80px; display: inline-block;">'+
                            '<span class="c-red">请求失败！</span></div>');
        })
    });

    $('#spread-detail .spread-users').on("click", ".pagination a",function(){
        if ($(this).attr('disabled') == 'disabled') {
            return false;
        };

        var sid = $('#spread-detail tbody tr').attr('name');
        // console.log('reloading sid: '+sid);

        // loading gif
        $('#spread-detail .spread-users').empty().append('<div style="position: relative; top: 10px; left: 320px; width: 40px; display: inline-block;">'+
                                                    '<img class="loading" src="/assets/od-icon/loading.gif"/></div>')
        // want to page
        var pager = parseInt($(this).text());
        if ( pager.toString() == "NaN" ){
            // should be prev or next a tag
            pager = parseInt($(this).attr('class'));
            if ($(this).attr('class').indexOf('prev')){
                pager = pager - 1;
            }else {
                pager = pager + 1;
            }
        }

        // ajax data
        $.ajax({
            type: "GET",
            url: '/users/survey_detail/'+sid+'?page='+pager,
            beforeSend: function(xhr){
                xhr.setRequestHeader("OJAX",true);
            }
        }).done(function(data){
            $('#spread-detail .spread-users').empty().append(data);
            $.fancybox.update();
        }).fail(function() { 
            $('#spread-detail .spread-users').empty().append('<div style="position: relative; top: 10px; left: 320px; width: 80px; display: inline-block;">'+
                            '<span class="c-red">请求失败！</span></div>');
        })
    });

});