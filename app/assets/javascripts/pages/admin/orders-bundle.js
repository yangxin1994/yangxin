jQuery(function($) {
  // 审核按钮

  $(document).on("click", ".od-accept",function(){
    order_id = $(this).attr('href');
    selfel = $(this);
    $.put("orders/" + order_id + "/verify",
    {
    },
    function(retval){
      if(retval.success)
      {
        selfel.parent().html("已接受")
        // $("#"+ order_id).fadeOut("slow").remove();
      }
      else
      {
            // 弹出消息 删除失败
      }
    });
    return false;
  });
  $(document).on("click", ".od-refuse",function(){
    order_id = $(this).attr('href');
    selfel = $(this);
    var refuse=prompt("请输入拒绝理由","");
    if(refuse)//如果返回的有内容
    {
      $.put("orders/" + order_id + "/verify_as_failed",
      {
        status_desc: refuse
      },
      function(retval){
        if(retval.success)
        {
          selfel.parent().html("已拒绝")
          // $("#"+ order_id).fadeOut("slow").remove();
        }
        else
        {
          // 弹出消息 删除失败
        }
      });
    }

    return false;
  });

  $(document).on("click", ".od-deliver",function(){
    order_id = $(this).attr('href');
    selfel = $(this);
    $.put("orders/" + order_id + "/deliver",
    {
    },
    function(retval){
      if(retval.success)
      {
        selfel.parent().html("已配送")
        // console.log($("#"+ order_id));
        // $("#"+ order_id).fadeOut("slow").remove();
      }
      else
      {
            // 弹出消息 删除失败
      }
    });
    return false;
  });

  $(document).on("click", ".od-delivered",function(){
    order_id = $(this).attr('href');
    selfel = $(this);
    $.put("orders/" + order_id + "/deliver_success",
    {
      status_desc: "配送成功"
      // status_desc: $("#status_desc").val(),
    },
    function(retval){
      if(retval.success)
      {
        selfel.parent().html("配送成功")
        // $("#"+ order_id).fadeOut("slow").remove();
      }
      else
      {
            // 弹出消息 删除失败
          }
        }
        );
    return false;
  });

  $(document).on("click", ".od-deliverefailed",function(){
    order_id = $(this).attr('href');
    selfel = $(this);
    $.put("orders/" + order_id + "/deliver_as_failed",
    {
      status_desc: "配送失败",
    },
    function(retval){
      if(retval.success)
      {
        selfel.parent().html("配送失败")
        // $("#"+ order_id).fadeOut("slow").remove();
      }
      else
      {
            // 弹出消息 删除失败
      }
    });
    return false;
  });
});