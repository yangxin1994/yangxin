#encoding: utf-8
# already tidied up

module OrdersHelper
  def user_info(order)
    op = ["full_name", "identity_card", "bank", "bankcard_number",
      "alipay_account", "phone", "address", "postcode", "email"]
    op_name = ["姓名", "证件号", "开户行", "银行卡号",
      "支付宝账号", "电话号码", "地址", "邮编", "电子邮箱"]
    result_str = ""
    op.each_with_index do |value, index|
      result_str += ("#{op_name[index]}:#{order[value].to_s}  ") unless order[value].nil?
    end
    result_str
  end

  def order_status_tag(status)
    
    case status.to_i
    when 1
      "等待处理"
    when 2
      "正在处理"
    when 4
      "已成功"
    when 8
      "已失败"
    when 16
      "样本取消"
    when 32
      "冻结"
    when 64
      "答案被拒绝"
    end
  end

  def order_label(type)
    case type.to_i
    when 1
      "收货信息"
    when 2
      "收货地址"
    when 4
      "电话号码"
    when 8
      "支付宝账号"
    when 16
      ""
    when 32
      "QQ号码"
    when 64
      "电话号码"
    else
      "收货信息"
    end
  end


end
