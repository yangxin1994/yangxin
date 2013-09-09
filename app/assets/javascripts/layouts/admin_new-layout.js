//= require handlebars.runtime
//= require utility/ajax
//= require utility/util

jQuery(function($) {

	// datatable
	if($('.dataTables_wrapper').length > 0){
		$('.dataTables_filter').parent().remove();
		$('.dataTables_length').parent().remove();
		$('.dataTables_wrapper').css('min-height', '20px');
		$('.dataTables_empty').text('未存在相应记录');
	}

	// checkbox
	if($('.jqTransformCheckboxWrapper').length > 0) {
		$.each($('.jqTransformCheckboxWrapper'), function(index, item){
			var checkbox = $(item).children('input:checkbox').removeClass('jqTransformHidden');
			$(item).after(checkbox);
			$(item).remove();
		})
	}

	// radio
	if($('.jqTransformRadioWrapper').length > 0) {
		$.each($('.jqTransformRadioWrapper'), function(index, item){
			var checkbox = $(item).children('input:radio').removeClass('jqTransformHidden');
			$(item).after(checkbox);
			$(item).remove();
		})
	}

	// remove footer
	// $('#footer').remove();

	// leftNav status
	var _surveys=['reviews', 'publishes', 'review_answers', 'template_questions', 'quality_questions', 'volunteer_surveys']
	var _gifts=['gifts']
	var _lotteries=['lotteries']
	var _orders =['orders']
	var _users = ['users']
  var _prizes = ['prizes']
	var _others = ['messages', 'advertisements', 'faqs', 'feedbacks', 'announcements']

	var current_path = window.location.pathname.split('/')[2]
	if(current_path==undefined){
		current_path="reviews"
	}
	if(_surveys.indexOf(current_path) > -1){
		$('li#nav-surveys ul').css('display', 'block')
	}else if(_gifts.indexOf(current_path) > -1){
		$('li#nav-gifts ul').css('display', 'block')
	}else if(_lotteries.indexOf(current_path) > -1){
		$('li#nav-lotteries ul').css('display', 'block')
	}else if(_orders.indexOf(current_path) > -1){
		$('li#nav-orders ul').css('display', 'block')
	}else if(_users.indexOf(current_path) > -1){
		$('li#nav-users ul').css('display', 'block')
	}else if (_prizes.indexOf(current_path) > -1) {
		$('li#nav-prizes ul').css('display', 'block')
  }else if(_others.indexOf(current_path) > -1){
		$('li#nav-others ul').css('display', 'block')
	}

});
