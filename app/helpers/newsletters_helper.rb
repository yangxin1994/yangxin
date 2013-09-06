#encoding: utf-8
# already tidied up

module NewslettersHelper

  def newsletter_status(newsletter)
    case newsletter["status"].to_i
    when 0
      "草稿"
    when -1
      "发送中(#{newsletter['delivered_count']}/#{newsletter['all_sub_count']})"
    when 1
      "发送完成(#{newsletter['delivered_count']}/#{newsletter['all_sub_count']})"
    when -2
      "发送中断(#{newsletter['delivered_count']}/#{newsletter['all_sub_count']})"
    else
      "好歹有个状态啊?!"
    end
  end

  # def ejournal_status(ejournal)
  #   case ejournal["status"]
  #   when 0
  #     "草稿(<a href=\"#{ejournal['_id']}\" class=\"od-edting\">点击发送</a>)".html_safe
  #   when -1
  #     "发送中(<a href=\"#{ejournal['_id']}\" class=\"od-delivering\">点击取消</a>)".html_safe
  #   when 1
  #     "发送完成(<a href=\"#{ejournal['_id']}\" class=\"od-delivered\">点击补发\</a>)".html_safe
  #   when -2
  #     "发送中断(<a href=\"#{ejournal['_id']}\" class=\"od-canceled\">点击重发</a>)".html_safe
  #   else
  #     "好歹有个状态啊?!"
  #   end
  # end

  def ck_public_tag(lottery)
    if lottery["status"].to_s == "3" || lottery["status"].to_s == "2"
      'checked'.html_safe
    end
  end


end
