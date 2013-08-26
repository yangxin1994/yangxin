//=require jquery.fancybox.pack
//=require jQuery.blockUI
//=require jquery.SuperSlide
//=require utility/ajax
//=require jquery.zclip
//=require jquery.highlight


// $(document).ready(function(){
//   $('.research-list ul .research-content:last').css('border-bottom','none');
//   jQuery(".slider").slide( { mainCell:".bd ul",effect:"leftLoop",autoPlay:true} );


//   $('.hourglass').each(function(){
//     end_time = $(this).attr('endtime');
//     if (end_time){
//       //end_time = new Date(end_time * 1000);
//       now = new Date();
//       during = end_time - now.getTime(); 
//       days  = Math.floor(during/(24*3600*1000));
//       leave1=during%(24*3600*1000)
//       hours=Math.floor(leave1/(3600*1000))   
//       leave2=leave1%(3600*1000) 
//       minutes=Math.floor(leave2/(60*1000))
//       leave3=leave2%(60*1000)
//       seconds=Math.round(leave3/1000)
//       dead = ''
//       if(during < 0){
//         $(this).after('已结束')
//       }else{ 
//         if(days > 0){
//           dead += days + '天'
//         }
//         if(hours > 0){
//           dead += ' ' + hours + '小时' 
//         }
//         if(minutes > 0){
//           dead += ' ' + minutes + '分钟'
//         }
//         dead = dead + ' ' + seconds + '秒 ' + '后结束'
//         $(this).after(dead)
//       }      
//     }

//   })

//   $('.unfold-btn').click(function(){
//     txt = $(this).children('.unfold').html();
//     link = $(this);
//     if(txt == '展开奖品'){
//       $(this).after('<span style="float:right;"><img class="loading" src="/assets/image/sample/fancybox_loading.gif" width="12" height="12" /></span>')
//       prize_ids = $(this).attr('data');
//       survey_id = $(this).attr('survey_id');
//       prizes_container = $(this).parents('span.research-meta').siblings('ul.reward_list');
//       // ajax request
//       $.postJSON('/prizes/find_by_ids.json',{ids:prize_ids},function(retval){
//         if(retval.success){
//           link.children('.unfold').html('收起奖品');
//           link.children("i").removeClass('open').addClass('close');
//           $(".loading").remove();
//           link.parents('.research-meta').siblings('.reward_list').show();
//           $.each(retval.value,function(index){
//             priz_index = 'priz' + index
//             tmp = '<li>\
//               <a href="#' + this._id + '" class="pop" rel="survey_' + prize_ids + 'data="'+ this._id +'" index="'+ index +'" >\
//                 <img src=" ' + this.photo_src + ' " alt="">\
//                 <span class="gift-mask"></span>\
//                 <div class="gift-name">\
//                   <div>' + this.title +   '</div>\
//                 </div></a></li>'
//             $(tmp).appendTo(prizes_container)
//             popup = '<div id="' + this._id + '" style="display:none;" class="pri1"> \
//               <div class="prize_info"> \
//                 <div class="detail"> \
//                   <div class="title">参与本次调研就有机会获得如下奖品</div> \
//                     <div class="prize_img"> \
//                       <img src="' + this.photo_src + '"/> \
//                     </div> \
//                   <div class="prize_intro"> \
//                   <p class="prize_title">' +  this.title + '</p> \
//                   <p class="prize_price">市场价: <span class="price_info">￥' + this.price + '</span></p> \
//                   <p> \
//                     <span class="p_intro">奖品介绍 :</span><br/> \
//                     <span class="intro_info">' + this.description + '</span>  \
//                   </p> \
//                   <button class="prize_btn" data="' + survey_id + '">立即参与</button> \
//                 </div> \
//                 <div style="clear:both;"></div> \
//                 <div class="slide_nav"> '
//             lis = ''
//             $.each(prize_ids.split(','),function(i){
//               lis += '<li class="slide"></li>'  
//             })
//             popup_1 = '</div></div></div></div>'
//           $(popup + lis + popup_1 ).appendTo(prizes_container)
//           })
//         }else{
//           console.log('^^^^^^^^^^^^^^^^^^^^^^^')
//           console.log(retval.value)
//           console.log('^^^^^^^^^^^^^^^^^^^^^^^')         
//         }
//       })

//     }else{
//       $(this).parents('.research-meta').siblings('.reward_list').hide();
//       $(this).children('.unfold').html('展开奖品');
//       $(this).children('i').removeClass('close').addClass('open');
//       $(this).next('span').remove();
//       prizes_container.html('');
//     }
    
//   })

//   $(".pop").fancybox({
//     beforeShow: function(){
//       $(".fancybox-skin").css({"backgroundColor":"#fff"});
//       target_id = $(this.element).attr('href');
//       slides =  $("div" + target_id ).find('.slide');  
//       slides.removeClass('current_slide');
//       $(slides[this.index]).addClass('current_slide')
//       if(this.index == 0) {
//         $(this.tpl.prev).appendTo($.fancybox.outer).css({"opacity":0.6});
//         $('.fancybox-prev').children('span').css({"background":"url(/assets/image/sample/prev_e.png) no-repeat"})
//       } else if( this.index < this.group.length){
//         $(this.tpl.next).appendTo($.fancybox.outer).css({"opacity":0.6});
//         $(".fancybox-next").children('span').css({"background":"url(/assets/image/sample/next_e.png) no-repeat"})
//       }    
//     },
//     afterShow: function(){
//       target_id = $(this.element).attr('href');
//       slides =  $("div" + target_id ).find('.slide');  
//       slides.removeClass('current_slide');
//       $(slides[this.index]).addClass('current_slide')
//     },
//     autoPlay: false,
//     nextEffect: 'fade',
//     prevEffect: 'fade',
//     width:654,
//     height:342,
//     scrolling:  'no',
//     padding : [20, 28, 20, 28],
//     closeBtn: true,
//     arrows:true,
//     loop:false
//   });

//   $('.prize_btn').live('click',function(){
//     survey_id = $(this).attr('data');
//     window.open("/surveys/" + survey_id,"_blank")
//     //window.location.href="/surveys/" + survey_id;
//   })

//   $('.share-btn').fancybox({
//     beforeShow: function(){
//       $(".fancybox-skin").css({"backgroundColor":"#fff"});
//       point = $(this.element).attr('data');
//       $("#share_survey").find('.p_num').html(point);
//       survey_id = $(this.element).attr('survey_id');
//       share_url =  window.location.origin + '/surveys/' + survey_id
//       $("#share_survey").find('.share_url').val(share_url);
//       var href = $('#survey_url').val();
//       var href_ipt = $('#survey_url').mouseover(function(e) { $(e.target).select(); });
//       var notice = $('div.second');
//       console.log(notice.html());
//       $('#copy_survey').click(function() {
//         if (window.clipboardData) { //IE
//           window.clipboardData.setData("Text", href);
//           if($('span.green').length < 1 ){
//             notice.after('<span class="green">链接已经复制至剪贴板</span>');
//             $('<span class="green">链接已经复制至剪贴板</span>').appendTo(notice)
//             $(".green").css({ backgroundColor: "green" });            
//           }
//         }else{
//           if($('span.red').length < 1 ){
//             notice.after('<span class="red">选择输入框里链接并鼠标右键或按 ctrl+c 进行复制。</span>');
//             $(".red").css({ backgroundColor: "red" ,color:'white'});            
//           }
//           href_ipt.select();
//         };  
//       });
//     },
//     afterClose: function(){
//       $('span.red').remove();
//       $('span.green').remove();   
//     },   
//     scrolling:  'no',  
//     padding : 8,
//     width:510,
//     height:230        
//   })

// })