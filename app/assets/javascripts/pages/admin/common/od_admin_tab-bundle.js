jQuery(function($) {

  function getQueryString(name) {
    var reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)", "i");
    var r = window.location.search.substr(1).match(reg);
    if (r != null) return unescape(r[2]); return null;
  }
  // console.log(getQueryString('scope'));
  // console.log($("#tab-" + (getQueryString('scope') || 'all')));

  $(".tab-label").click(function(event){
    var scope = $(event.target).attr("id").replace(/tab-/,'');
    $(".tab-content").attr('style','display: none;');
    $("#" + scope).attr('style','display: block;');
    if($("#" + scope + ":has(table)").length!=0){return true;}
    $.get('',
    {
      scope: scope,
      render_div: scope,
      partial: true
    },
    function(retval){
      window.crt_pagi_fun = function(val){
        $("#" + scope).html(val);
      };
      console.log($("#" + scope));
      $("#" + scope).html(retval);
    });
    return true;
  });

  $("#tab-" + (getQueryString('scope') || 'all')).click();

});