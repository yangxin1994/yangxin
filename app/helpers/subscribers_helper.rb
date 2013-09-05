# encoding: utf-8

module SubscribersHelper

  def subscribe_status(subscriber)
    case subscriber["is_deleted"]
    when true
      "<a href=\"#{subscriber['_id']}\" class=\"od-resubscribe-btn\">添加订阅</a>".html_safe
    when false
      "<a href=\"#{subscriber['_id']}\" class=\"od-unsubscribe-btn\">取消订阅</a>".html_safe
    else
      subscriber["is_deleted"]
    end
  end
end
