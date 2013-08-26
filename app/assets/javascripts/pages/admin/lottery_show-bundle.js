jQuery(function($) {
  $('.content-box .content-box-content div.tab-content').hide(); 
  $('ul.content-box-tabs li a.default-tab').addClass('current'); 
  $('.content-box-content div.default-tab').show();
  $('.content-box ul.content-box-tabs li a.tab-label').click( 
    function() { 
      tab = $(this);
      tab.parent().siblings().find("a").removeClass('current'); 
      tab.addClass('current'); 
      var currentTab = tab.attr('href'); 
      $(currentTab).siblings().hide(); 
      $(currentTab).show(); 
      return false;
    });
  // <!-- 单选按钮美化 -->

    $(".cb-enable").click(function(){
      $.put("/admin/prizes/" + this.getAttribute("_id") + '.json',
      {
        prize: {
          status: 1
        }
      },
      function(retval){
      });
      var parent = $(this).parents('.switch');
      $('.cb-disable',parent).removeClass('selected');
      $(this).addClass('selected');
      $('.checkbox',parent).attr('checked', true);
    });
    $(".cb-disable").click(function(){
      $.put("/admin/prizes/" + this.getAttribute("_id") + '.json',
        {
          prize: {
            status: 0
          }
        },
        function(retval){}
      );
      var parent = $(this).parents('.switch');
      $('.cb-enable', parent).removeClass('selected');
      $(this).addClass('selected');
      $('.checkbox', parent).attr('checked', false);
    });
    // 删除按钮
    $(".od-delete").click(function(){
      prize_id = this.getAttribute("_id");
      $.delete("/admin/prizes/" + prize_id,
      {
      },
      function(retval){
        if(retval.success)
        {
          $("#"+ prize_id).fadeOut("slow");
        }
        else
        {
                // 弹出消息 删除失败
        }
      }
      );
      return false;
    });

  $(document).ready( function(){ 
    $(".od-lottery-prize").click(function(){
      var user_id = $(this).attr('_id');
      var prize_id = $("#prize_" + user_id).val();
      $.put($('table').attr('id') + "/assign_prize",
      {
        user_id: user_id,
        prize_id: prize_id
      },
      function(retval){
        if(retval.success)
        {
          console.log(prize_id);
          //$("#" + lottery_id).fadeOut("slow");
        }
        else
        {
          // 弹出消息 删除失败
        }
        });
        return false;
    });
  });

  $("#tab-prize-records").click(function(){
    $.get(window._lottery._id + "/prize_records",
    {
      render_div: "prize-records"
    },
    function(retval){
      // window.crt_pagi = window._lottery._id + "/prize_records";
      // window.crt_pagi_fun = function(val){
      //   $("#prize-records").html(val);
      // };
      $("#prize-records").html(retval);
    });
    return false;
  });

  $("#tab-lottery_codes").click(function(){
    $.get(window._lottery._id + "/lottery_codes",
    {
      render_div: "lottery_codes"
    },
    function(retval){
      // window.crt_pagi = window._lottery._id + "/lottery_codes";
      // window.crt_pagi_fun = function(val){
      //   $("#lottery_codes").html(val);
      // };
      $("#lottery_codes").html(retval);
    });
    return false;
  });

  $("#tab-list_user").click(function(){
    $.get(window._lottery._id + "/list_user",
    {
      render_div: "list_user"
    },
    function(retval){
      // window.crt_pagi = window._lottery._id + "/list_user";
      // window.crt_pagi_fun = function(val){
      //   $("#list_user").html(val);
      // };
      $("#list_user").html(retval);
      $(document).on("click", ".assign_prize", function(val){
        lottery_id = window._lottery._id;
        user_id = val.currentTarget.id;
        console.log(val.currentTarget.id);
        $.put(lottery_id + '/assign_prize',
          {
            user_id: user_id,
            prize_id: $("#prize_" + user_id).val()          
          },
          function(retval){
            if(retval.success)
            {

            }
            else
            {
                    // 弹出消息 删除失败
            }
          },"json"
        );
        return false;
      });
    });
  });

  $("#tab-edit").click(function(){
    lottery_id = window._lottery._id;
    $.get(lottery_id + '.json',
      {},
      function(retval){
        if(retval.success)
        {
          $("#lottery-form").attr('action', '/admin/lotteries/' + lottery_id);
          $("#lottery_method").attr('value', 'put');
          $("#lottery-photo").attr('src',retval.value.photo_src);
          $.each(retval.value, function(key, value) {
            $("#lottery-" + key).val(retval.value[key]);
          });
        }
        else
        {
          // 弹出消息 删除失败
        }
      },"json"
    );
  });

  $(".od-edit").click(function(){
    prize_id = this.getAttribute("_id");
    tab = $("#tab-prize");
    tab.text("编辑礼品");
    tab.parent().siblings().find("a").removeClass('current'); 
    tab.addClass('current'); 
    var currentTab = tab.attr('href'); 
    $(currentTab).siblings().hide(); 
    $(currentTab).show(); 
    $.get("/admin/prizes/" + prize_id + '.json',
      {},
      function(retval){
        console.log(retval);
        if(retval.success)
        {
          $("#prize-form").attr('action', '/admin/prizes/' + prize_id);
          $("#_method").attr('value', 'put');
          // for(k in retval.value){
          //   $("#prize-" + k).val(retval.value[k]);
          // }
          $.each(retval.value, function(key, value) {
            $("#prize-" + key).val(retval.value[key]);
          });
          if($("#prize-type").val() == 3)
          {
            $("#prize-lottery_id").attr("style",'');
          }
          else
          {
            $("#prize-lottery_id").attr("style",'visibility:hidden;');
          }
          $("#prize-photo").attr('src',retval.value.photo_src);
        }
        else
        {
                // 弹出消息 删除失败
        }
      },"json"
    );
      return false;
    });

});