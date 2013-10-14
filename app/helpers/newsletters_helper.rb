#encoding: utf-8
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

  def ck_public_tag(lottery)
    if lottery["status"].to_s == "3" || lottery["status"].to_s == "2"
      'checked'.html_safe
    end
  end
end
