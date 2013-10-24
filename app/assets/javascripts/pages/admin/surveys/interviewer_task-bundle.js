//= require utility/ajax
$(function(){
  num_reg = /^[0-9]*[1-9][0-9]*$/;
  $('tbody td#amount').click(function(){
    $currtd = $(this);
    if ($currtd.children("input").length > 0) { 
      return false; 
    }
    task_id = $(this).parent('tr').attr('data')
    tdtext = $currtd.html();
    $currtd.html(""); 
    var inputOjb = $("<input type='text' />").css('margin','0px').height('16px')
    .width('50px').val(tdtext).appendTo($currtd);

    inputOjb.trigger("focus").trigger("select"); 

    inputOjb.click(function() { 
      return false; 
    });

    inputOjb.keyup(function(event) { 
      var keyCode = event.which; 
      if (keyCode == 13) { 
          var inputText = $(this).val(); 
          inputText = inputText.replace(' ', '')
          $currtd.html(parseInt(inputText)); 
          send_data(task_id,parseInt(inputText))
      } 

      if (keyCode == 27) { 
          $currtd.html(parseInt(inputText));
          send_data(task_id,parseInt(inputText)) 
      } 
    })

    inputOjb.bind('blur',function(){
      var inputText = $(this).val();
       inputText = inputText.replace(' ', '')
      $currtd.html(parseInt(inputText));
      send_data(task_id,parseInt(inputText)) 
    })


    function send_data(tid,num){
      $.putJSON(
      '/admin/surveys/' + window.survey_id + '/update_amount',
      {
        task_id:tid,
        amount:num 
      }, function(data){
        console.log(data)
      });
    }

  })

  $('a.interviewer').click(function(){
    user_id = $(this).attr('id');
    $('input[name="user_id"]').val(user_id);
  })

  $('#confirm_add').click(function(){
    user_id = $('input[name="user_id"]').val();
    amount  = $('input[name="amount"]').val();

    if(user_id.length < 1){
      $('.alert-danger').find('span').remove();
      $('.alert-danger').append('<span>请选择访问员</span>').show();
      return false;
    }

    if(amount.length < 1 || isNaN(amount) || !num_reg.test(amount)){
      $('.alert-danger').find('span').remove();
      $('.alert-danger').append('<span>回收数量必须是大于0的整数</span>').show();
      return false;
    }
  })


})