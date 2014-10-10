$(function(){

	$('.button-list .btn').click(function(){
		var m_id = $(this).data('id')
		var t = $(this).data('t')
		$.get('/vote/suffrages/statrt_vote',{movie_id:m_id,vt:t},function(ret){
			if (ret.success){
				window.location.href = '/vote/suffrages'
			}
		})
	})
})