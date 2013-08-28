  $('.btn-choice-delete').click(function(){
    var _id = $(this).parent().attr('id');
    $('.choices #'+_id).remove();
    $('.answer-choices #'+_id).remove();
    return false;
  });