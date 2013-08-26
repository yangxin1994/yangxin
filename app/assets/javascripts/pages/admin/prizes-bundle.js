//= require jquery-interdependencies

jQuery(function($) {

  $('.searchWidget form').submit(function() {
    $this = $(this);
    if($this.find('[name=title]').val() == '按照标题搜索') {
      $this.find('[name=title]').val('');
    }
  });

  var set_rules_for_panels =  function() {
    var build_property_form_rules = function(selector) {
      var cfg = {
        hide: function(control) {
          control.find('input, textarea, select').attr('disabled', true);
          control.hide();
        },
        show: function(control) {
          control.find('input, textarea, select').attr('disabled', false);
          control.show();
        }
      };

      var ruleset = $.deps.createRuleset();

      var normal_rule = ruleset.createRule('[name="prize[type]"]', 'any', ['32', '8', '16']);
      normal_rule.include('div.formRight.normal');
      var array_rule = ruleset.createRule('[name="prize[type]"]', '==', '4');
      array_rule.include('div.formRight.select');

      $.deps.enable($(selector), ruleset, cfg);
    };

    build_property_form_rules('#prize_form');
  };

  set_rules_for_panels();


  // 删除按钮
  $(".od-delete").click(function(e){
    e.preventDefault();
    $this = $(this);
    prize_id = $this.data('id');
    $.delete("prizes/" + prize_id, function(retval) {
      if(retval.success) $this.closest('tr').fadeOut("slow");
    });
  });

  $('#prize_form').validationEngine();

  // set value
  type = $('[name="prize[type]"]').val();
  amount = $('[name="prize[type]"]').data('amount');
  $('[name="prize[type]"]').change();
  $('[name="prize[amount]"]').val(amount);
});
