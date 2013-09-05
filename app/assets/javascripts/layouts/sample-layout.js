//=require jquery.fancybox.pack
//=require jQuery.blockUI
//=require jquery.SuperSlide
//=require jquery.zclip
//=require jquery.highlight
//=require jquery-powerFloat-min
//=require ui/widgets/od_share
//=require ui/plugins/od_enter

$(document).ready(function(){
	var partial_ul = null;
	var share_imgs = null;
	$.form.powerfloat();
	
	$.each([$('.share-btn'),$('a.old')],function(){
		$(this).click(function(){
			$.od.odShare({
				point:$(this).attr('data'),
				survey_title:$(this).attr('s_title'),
				scheme_id:$(this).attr('scheme_id'),
				images:$(this).parents('li').find('a.unfold-btn').attr('prize_src')
			});
		});
	})




	jQuery(".slider").slide( { mainCell:".bd ul",effect:"leftLoop",autoPlay:true} );

	$('input, textarea').placeholder();
  	// placeholder for IE 
  	//$.form.placeholder();
  	$('input, textarea').placeholder();

	$('.unfold-btn').toggle(function(){
		$(this).children('i').removeClass('open').addClass('close').next('span').html('收起');
		$(this).parents('.research-meta').siblings('.reward_list').show();
	},function(){
		$(this).children('i').removeClass('close').addClass('open').next('span').html('展开');
		$(this).parents('.research-meta').siblings('.reward_list').hide();
	})


	$(".pop").fancybox({
		beforeShow: function(){
			$(".fancybox-skin").css({"backgroundColor":"#fff"});
			var target_id = $(this.element).attr('href');
			var slides =  $("div" + target_id ).find('.slide');  
			slides.removeClass('current_slide');
			$(slides[this.index]).addClass('current_slide')
			if(this.index == 0) {
				$(this.tpl.prev).appendTo($.fancybox.outer).css({"opacity":0.6});
				$('.fancybox-prev').children('span').css({"background":"url(/assets/image/sample/prev_e.jpg)","background-repeat":"no-repeat"})
			} else if( this.index < this.group.length){
				$(this.tpl.next).appendTo($.fancybox.outer).css({"opacity":0.6});
				$(".fancybox-next").children('span').css({"background":"url(/assets/image/sample/next_e.jpg)","background-repeat":"no-repeat"})
			}    
		},
		afterShow: function(){
			var target_id = $(this.element).attr('href');  
			var slides =  $("div" + target_id ).find('.slide');  
			slides.removeClass('current_slide');
			$(slides[this.index]).addClass('current_slide')
		},
		autoPlay: false,
		nextEffect: 'none',
		prevEffect: 'none',				
		width:654,
		height:362,
		scrolling:  'no',
		padding : [20, 28, 20, 28],
		closeBtn: true,
		arrows:true,
		loop:false
	});

})