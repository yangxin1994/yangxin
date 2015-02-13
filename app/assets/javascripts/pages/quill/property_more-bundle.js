//=require ui/widgets/od_popup

jQuery(function($) {
	//NOTE: window.survey_id refers to the current opened survey id
	$("input:checked").next().addClass('bold');

	if($('.redirect').val()==""){
		$('.redirect').attr("disabled",true);
	}
	$('.moreSelector li:last img').hide();

	var checkTitle = ['has_progress_bar','is_one_question_per_page',
		'has_question_number','allow_pageup', 'allow_replay', 'allow_multianswer',
    'cancel_time_limit', 'cancel_time_shown', 'has_advertisement','has_oopsdata_link','redirect_link'];

	$('.moreSelector .choice').change(function(){
		var id = $(this).parentsUntil('li').parent().index();
		var param = {};

		if(this.checked){
			$(this).next().addClass('bold');
			param[checkTitle[id]] = true ; 			
		}else{
			$(this).next().removeClass('bold');
			param[checkTitle[id]] = false;
		}
		$.putJSON('/questionaires/' + window.survey_id + '/property/update_more.json', param, 
			function(retval) {
			if(retval.success) {
				console.log('success!');
			} else {
				console.log('update more error!');
			}
		});
	});

	var linkURL="";
	$('.redirect').focus(function(){
		$(".accept").hide();
		linkURL=$(this).val();
	});
	$('.redirect').blur(function(){
		var link = $('.redirect').val();
		if(linkURL!=link || link==""){
			if(link==""){
				$(this).attr("disabled",true);
				$('.accept').hide();
				$('.redirect_li').next().removeClass('bold');
				$('.redirect_li').removeAttr("checked");
			}
			else{
				$(this).attr("disabled",false);
				$(".wait").show();
				$('.redirect_li').next().addClass('bold');
				$('.redirect_li').attr("checked","checked");
			}
			$.putJSON('/questionaires/' + window.survey_id + '/property/update_more.json', {"redirect_link":link}, 
				function(retval) {
				if(retval.success) {
					console.log('success!');
					if(link!=""){
						$('.accept').show();
						$(".wait").hide();
					}
				}else{
					console.log('update more error!');
				}
			});
		}			
	});

	$('.redirect_li').click(function(){
		if(this.checked){
			$('.redirect').attr("disabled",false);
			$(this).next().addClass('bold');	
		}else{
			$('.redirect').attr("disabled",true);
			$('.redirect').val("");
			$('.accept').hide();
			$(this).next().removeClass('bold');

			$.putJSON('/questionaires/' + window.survey_id + '/property/update_more.json', {"redirect_link":""}, 
				function(retval) {
				if(retval.success) {
					console.log('success!');
				} else {
					console.log('update more error!');
				}
			});
		}
	});

});