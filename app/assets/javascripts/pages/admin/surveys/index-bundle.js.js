// Generated by CoffeeScript 1.6.3
$(function() {
  $(".dropselect a").click(function() {
    var $this;
    $this = $(this);
    return $("#key_type").val($this.data('toggle'));
  });
  $(".info").click(function() {
    var $this;
    $this = $(this).closest('td');
    $("#sid").val($this.data("sid"));
    return $.ajax({
      url: "/admin/surveys/" + ($this.data("sid")) + "/more_info",
      method: "GET",
      success: function(ret) {
        if (ret.success) {
          $("#ck_hot").prop("checked", ret.value.hot);
          $("#point").val(ret.value.spread);
          if (ret.value.visible) {
            $("#ck_visible").prop("checked", true);
          }
          $("#max_num_per_ip").val(ret.value.max_num_per_ip);
          return $('#info_modal').modal('show');
        } else {
          console.log(ret);
          return alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ");
        }
      },
      error: function() {
        return alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ");
      }
    });
  });
  $(".promote").click(function() {
    var $this;
    $this = $(this).closest('td');
    $("#sid").val($this.data("sid"));
    $('#promote_modal').modal('show');
    return $.ajax({
      url: "/admin/surveys/" + ($this.data("sid")) + "/promote_info",
      method: "GET",
      success: function(ret) {
        console.log(ret);
        if (ret.success) {
          return $("#email_sended").html(ret.value.email.promote_email_count);
        } else {
          console.log(ret);
          return alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ");
        }
      },
      error: function() {
        return alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ");
      }
    });
  });
  $(".cost").click(function() {
    var $this, reward_item;
    $this = $(this).closest('td');
    $("#sid").val($this.data("sid"));
    reward_item = function(item) {
      var reward, reward_type, str, _i, _len, _ref;
      str = '';
      if (item.rewards.length > 0) {
        _ref = item.rewards;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          reward = _ref[_i];
          reward_type = "";
          if (reward.type === 1) {
            reward_type = "虚拟";
          } else if (reward.type === 2) {
            reward_type = "实物";
          } else if (reward.type === 4) {
            reward_type = "话费";
          } else if (reward.type === 8) {
            reward_type = "支付宝";
          } else if (reward.type === 16) {
            reward_type = "集分宝";
          } else if (reward.type === 32) {
            reward_type = "Q币";
          }
          str += "<p>&nbsp;&nbsp;&nbsp;&nbsp;奖励类型 - " + reward_type + ": " + reward.amount + "</p>";
        }
      }
      return str;
    };
    return $.ajax({
      url: "/admin/surveys/" + ($this.data("sid")) + "/cost_info",
      method: "GET",
      success: function(ret) {
        var item, _i, _len, _ref;
        if (ret.success) {
          $("#cost_body").html("<div id=\"cost_item\"></div>");
          _ref = ret.value;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            item = _ref[_i];
            if (item) {
              $("#cost_item").append("<p>奖励方案 - " + item.name + ":\n  <br>\n  " + (reward_item(item)) + "\n</p>");
            }
          }
          return $('#cost_modal').modal('show');
        } else {
          console.log(ret);
          return alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ");
        }
      },
      error: function() {
        return alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ");
      }
    });
  });
  $("#send_info").click(function() {
    $('#info_modal').modal('hide');
    alert_msg.show('info', "正在处理,请稍后...");
    return $.ajax({
      url: "/admin/surveys/" + ($("#sid").val()) + "/set_info",
      method: 'PUT',
      data: {
        hot: $("#ck_hot").prop("checked"),
        spread: $("#point").val(),
        visible: $("#ck_visible").prop("checked"),
        max_num_per_ip: $("#max_num_per_ip").val()
      },
      success: function(ret) {
        if (ret.success) {
          return alert_msg.show('success', "操作完成!");
        } else {
          console.log(ret);
          return alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ");
        }
      },
      error: function() {
        return alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ");
      }
    });
  });
  return $(".star").click(function() {
    var $this, icon;
    $this = $(this);
    icon = $this.find('i');
    return $.ajax({
      url: "/admin/surveys/" + ($this.data("id")) + "/star",
      method: 'PUT',
      data: {
        star: icon.hasClass('icon-star')
      },
      success: function(ret) {
        if (ret.success) {
          return icon.attr('class', "icon-star" + (ret.value ? "" : "-empty"));
        } else {
          return alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ");
        }
      },
      error: function() {
        return alert_msg.show('error', "处理失败,请稍后重试 (╯‵□′)╯︵┻━┻ ");
      }
    });
  });
});