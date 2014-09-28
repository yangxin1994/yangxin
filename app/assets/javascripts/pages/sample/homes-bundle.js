jQuery(function(){
  var aLi = $('.vote-class li');
  var aDiv = $('.vote-list');
  aLi.click(function() {
    aLi.removeClass('active');
    $(this).addClass('active');
    aDiv.removeClass('dn');
    aDiv.eq($(this).index()).addClass('dn');
  });
});