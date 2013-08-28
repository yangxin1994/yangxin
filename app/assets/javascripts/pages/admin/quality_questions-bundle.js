//= require jquery-migrate-1.0.0.min
//= require jquery-ui-min

jQuery(function($) {


  //***************
  //
  //  show page
  //
  //***********************

  //blur
  $('#edit-tab [name="quality_question[:min_choice]"], #edit-tab [name="quality_question[:max_choice]"]').blur(function(){
    if(parseInt(this.value).toString() == "NaN")
    {
      $(this).parent().children('.alertSpan').text("请输入正确的数字");
      $(this).addClass('error');
    }else{
      $(this).parent().children('.alertSpan').text("");
      $(this).removeClass('error');
    }
  });

  $('.new-choice').click(function(e){
    var q_id=$(this).closest('.quality_question').attr('id');
    var $item=$('#choice-item').clone(true);
    $item.removeClass('dn')
      .addClass('choice')
      .attr('id','choice-'+$.util.uid());
      
    // add new choice item of draggable
    $item.draggable({
      cancel: "input", // clicking an icon won't initiate dragging
      revert: "invalid", // when not dropped, the item will revert back to its initial position
      containment: "document",
      helper: "clone",
      cursor: "move"
    });

    $item.appendTo('#'+q_id+' .choices');
    return false;
  });

  $('.btn-choice-delete').click(function(){
    var _id = $(this).parent().data('id');
    $('.choices #'+_id).remove();
    $('.answer-choices #'+_id).remove();
    return false;
  });

  // 
  // Combine questions and answer
  // 

  $('.btn-edit-ok').click(function() {
    // Save question
    var _has_error=false;
    $.each($('#edit-tab [name^="quality_question"]'), function(index, value){
      if($(value).hasClass('error')){
        _has_error = true;
        return false;
      }
    });
    if(_has_error || $('.choice').length == 0){
      alert("更新信息存在错误，请修正");
      return false;
    }

    if($('.answer-choices .group').length==0){
      alert("请添加答案组");
      return false;
    }

    // loop to save
    $.each($('.quality_question'), function(index, item){
      var _q_id = $(item).attr('id');
      var _min_choice = parseInt($('#edit-tab #'+_q_id+' [name="quality_question[:min_choice]"]').val());
      var _max_choice=parseInt($('#edit-tab #'+_q_id+' [name="quality_question[:max_choice]"]').val());
      var _content=$('#edit-tab #'+_q_id+' [name="quality_question[:content]"]').val();
      var _items=new Array($('#edit-tab #'+_q_id+' .choices .choice').length);
      $.each($('#edit-tab #'+_q_id+' .choices .choice .choice-text'), function(index, obj){
        var _item = {
          content: {
            text: $(obj).val(),
            video: "",
            image: "",
            audio: ""
          }, 
          id: $(obj).parent().attr('id').split('-')[1]
        }
        _items[index] = _item;
      });

      $('.blueBtn').attr('disabled', 'disabled')
      $.put('/admin/quality_questions/'+_q_id,
        {
          content: _content,
          min_choice: _min_choice,
          max_choice: _max_choice,
          items: _items
        }, 
        function(data){
          // console.log(data);
          // $('.blueBtn').removeAttr('disabled');
          if(data.success){
            // alert("更新成功");
          }else{
            if(data.value.error_code == undefined){
              alert("更新失败");
              return false
            }else{
              var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
              alert(info);
              return false
            }
          }
        }
      );
    })

    // **********

    // Save answer

    var _a_id = $('.quality_control_question_answer').attr('id');
    var _quality_control_type=$('#edit-tab #'+_a_id+' [name=quality_control_type]').val();

    if(_quality_control_type==1){
      var _items=new Array($('.answer-choices .group').children('.choice').length);
      $.each($('.answer-choices .group').children('.choice'), function(index, obj){
        _items[index] = $(obj).attr('id').split('-')[1].toString();
      });

      // console.log(_items);
      // $('.blueBtn').attr('disabled', 'disabled')
      $.put('/admin/quality_questions/'+window.location.pathname.split('/')[3]+'/update_answer',
        {
          quality_control_type: _quality_control_type, 
          answer_content: {
            fuzzy: false, 
            items: _items
          }
        }, 
        function(data){
          $('.blueBtn').removeAttr('disabled');
          if(data.success){
            alert("更新成功");
          }else{
            if(data.value.error_code == undefined){
              alert("更新失败");
            }else{
              var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
              alert(info);
            }
          }
        }
      );
    }else{
      //remove empty group
      $.each($('.answer-choices .group'), function(index, group){
        if($(group).children('.choice').length==0){
          $(group).remove();
        }
      });

      var _items=new Array($('.answer-choices .group').length);
      $.each($('.answer-choices .group'), function(index, group){
        var _subItems=new Array($(group).children('.choice').length);
        $.each($(group).children('.choice'), function(index2, choice){
          _subItems[index2] = $(choice).attr('id').split('-')[1].toString();
        });
        _items[index] = _subItems;
      });

      // console.log(_items);
      if(_items[0]==undefined){
        _items =[];
      }

      // $('.blueBtn').attr('disabled', 'disabled')
      $.put('/admin/quality_questions/'+window.location.pathname.split('/')[3]+'/update_answer',
        {
          quality_control_type: _quality_control_type, 
          answer_content: {
            matching_items: _items
          }
        }, 
        function(data){
          $('.blueBtn').removeAttr('disabled')
          if(data.success){
            alert("更新成功");            
          }else{
            if(data.value.error_code == undefined){
              alert("更新失败");
            }else{
              var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
              alert(info);
            }
          }
        }
      );
    }
    return false;
  });

  //diff type, diff init
  if(window.quality_control_question_answer != undefined){
    if(window.quality_control_question_answer.quality_control_type == 1){
      // init one group
      $('.answer-choices').append('<div class="group group-1"><div title="唯一组不能删除"></span>拖拽</span></div></div>');
      //load db answer data
      var _items = []
      if(window.quality_control_question_answer.answer_content.items !=undefined){
        _items =window.quality_control_question_answer.answer_content.items;
      }
      $.each(_items,function(index, choice_id){
        $('#choice-'+choice_id).clone(true)
          .children('input').addClass('dn')
          .parent().append('<span>'+$('#choice-'+choice_id).children('input[type=text]').val()+'</span>')
          .appendTo('.answer-choices .group-1');
      });
    }else{
      //load db answer data
      var _items = []
      if(window.quality_control_question_answer.answer_content.matching_items !=undefined){
        _items =window.quality_control_question_answer.answer_content.matching_items;
      }
      $.each(window.quality_control_question_answer.answer_content.matching_items,function(index, group){
        $('.answer-choices').append('<div class="group group-'+(index+1)+'"><div class="drag-group" title="拖拽删除"></span>拖拽</span></div></div>');
        $.each(group, function(index2, choice_id){
          // maybe other group has these answer choices, so select first one.
          $($('#choice-'+choice_id)[0]).clone()
            .children('input').addClass('dn')
            .parent().append('<span>'+$($('#choice-'+choice_id)[0]).children('input[type=text]').val()+'</span>')
            .appendTo('.answer-choices .group-'+(index+1));
        });
      });

      // Some choices have beed deleted which were in questions and saved to db,
      // but the answer groups were not saved. Then, it will appears some empty answer groups
      // in frontend that they actually have answer choices in db and were insignificance.
      // so remove them!
      $.each($('.answer-choices .group'), function(index, group){
        if($(group).children('.choice').size() == 0){
          $(group).remove()
        }
      });

      //add group btn
      $('.quality_control_question_answer select[name=question_type]').after('<label style="width:40px;"></label><input class="blueBtn btn-add-group" type="button" value="添加答案组"/>')

      // init one group
      if($('.answer-choices').children().length==0){
        $('.answer-choices').append('<div class="group group-1"></div>');
      }
    }
  }

  // let the gallery items be draggable
  $('.choice, .answer-choices .drag-choice, .drag-group').draggable({
    cancel: "input", // clicking an icon won't initiate dragging
    revert: "invalid", // when not dropped, the item will revert back to its initial position
    containment: "document",
    helper: "clone",
    cursor: "move"
  });

  // let the trash be droppable, accepting the gallery items
  // each group
  $.each($('.answer-choices .group'), function(index, group){
    $(group).droppable({
      accept: ".choice",
      activeClass: "ui-state-highlight",
      drop: function( event, ui ) {
        $item = ui.draggable;
        if($(group).children('#'+$item.attr('id')).length==0){
          // $item.clone().children('input').addClass('dn').parent().appendTo(group);
          $item.clone()
            .children('input').addClass('dn')
            .parent().append('<span>'+$item.children('input[type=text]').val()+'</span>')
            .appendTo(group);
        }

        $('.answer-choices .drag-choice').draggable({
          cancel: "input", // clicking an icon won't initiate dragging
          revert: "invalid", // when not dropped, the item will revert back to its initial position
          containment: "document",
          helper: "clone",
          cursor: "move"
        });
      }
    });
  }); 

  $('body').droppable({
    accept: ".answer-choices .drag-choice, .answer-choices .drag-group",
    activeClass: '',
    drop: function( event, ui ) {
      $item = ui.draggable;
      $item.parent().remove();
    }
  });

  // add a new answer group
  $('.btn-add-group').click(function(){
    var len = $('.answer-choices').children().length+1;
    $('.answer-choices').append('<div class="group group-'+len+' ui-droppable"><div class="drag-group" title="拖拽删除"></span>拖拽</span></div></div>');

    $('.drag-group').draggable({
      cancel: "input", // clicking an icon won't initiate dragging
      revert: "invalid", // when not dropped, the item will revert back to its initial position
      containment: "document",
      helper: "clone",
      cursor: "move"
    });

    $('.answer-choices .group-'+len).droppable({
      accept: ".choices .choice",
      activeClass: "ui-state-highlight",
      drop: function( event, ui ) {
        $item = ui.draggable;
        if($('.answer-choices .group-'+len).children('#'+$item.attr('id')).length==0){
          // $item.clone().appendTo('.answer-choices .group-'+len);
          $item.clone()
            .children('input').addClass('dn')
            .parent().append('<span>'+$item.children('input[type=text]').val()+'</span>')
            .appendTo('.answer-choices .group-'+len);
        }

        $('.answer-choices .drag-choice').draggable({
          cancel: "input", // clicking an icon won't initiate dragging
          revert: "invalid", // when not dropped, the item will revert back to its initial position
          containment: "document",
          helper: "clone",
          cursor: "move"
        });
      }
    });
  });


  // *********************
  //
  // new page
  // 
  // ****************************

  $('#new-tab select[name=quality_control_type]').change(function(){
    if($(this).val() == 2){
      $('#new-tab input[name=question_number]').removeAttr('disabled')
    }else{
      $('#new-tab input[name=question_number]').attr('disabled','disabled')
    }
  });

  $('#new-tab .btn-new-ok').click(function(){
    //verify present
    var _qct = $('#new-tab select[name=quality_control_type]').val().trim();
    var _qt = $('#new-tab select[name=question_type]').val().trim();
    var _qn=$('#new-tab input[name=question_number]').val().trim();
    _qn = (_qn=="" ? 1 : _qn)

    $('.blueBtn').attr('disabled', 'disabled')
    $.post('/admin/quality_questions', 
      {quality_control_type: _qct, question_type: _qt, question_number: _qn},
      function(data){
        $('.blueBtn').removeAttr('disabled')
        // console.log(data);
        if(data.success){
          alert("创建成功");
          window.location.replace('/admin/quality_questions/'+data.value[0]._id)
        }else{
          if(data.value.error_code == undefined){
            alert("创建失败");
          }else{
            var info = "<p><em>Error</em>:<span>"+data.value.error_code+"</span></p><p><em>Message</em>:<span>"+data.value.error_message+"</span></p>";
            alert(info);
          }
        }
      });
  });

});