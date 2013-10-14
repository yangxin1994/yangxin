# encoding: utf-8
module SamplesHelper
  def point_reason(_r)
    case _r.to_i
    when 1
      "回答问卷"
    when 2
      "推广问卷"
    when 4
      "礼品兑换"
    when 8
      "管理员操作"
    when 16
      "处罚操作"
    when 32
      "邀请样本"
    when 64
      "撤销订单"
    when 128
      "原有系统导入"       
    else
      "其它"
    end
  end

  def attribute_type(_t)
    case _t.to_i
    when 0
      "字符串"
    when 1
      "枚举"
    when 2
      "数值"
    when 3
      "日期"
    when 4
      "数值范围"
    when 5
      "日期范围"
    when 6
      "地址"
    when 7
      "数组"
    end
  end

  def attr_tag(attr)
    case attr['type'].to_i
    when 0
      attr_string attr
    when 1
      attr_emun attr
    when 2
      attr_number attr
    when 3
      attr_date attr
    when 4
      attr_num_range attr
    when 5
      attr_date_range attr
    when 6
      attr_address attr
    when 7
      attr_array attr
    end
  end

  private

  def attr_string(attr)
    attr['value']
  end

  def attr_emun(attr)
    attr['enum_array'][attr['value']] if attr['value'].present?
  end

  def attr_number(attr)
    attr['value']
  end

  def attr_date(attr)
    case attr['date_type']
    when 0
      attr['strf'] = "%Y"
    when 1
      attr['strf'] = "%Y-%m"
    when 2
      attr['strf'] = "%F"
    end    
    Time.at(attr['value']).strftime(attr['strf'])
  end
  def attr_num_range(attr)
    if attr['value'][0] == attr['value'][1]
      attr['value'][0]
    else
      "#{attr['value'][0]} ~ #{attr['value'][1]}"
    end if attr['value'].present?
  end

  def attr_date_range(attr)
    case attr['date_type']
    when 0
      attr['strf'] = "%Y"
    when 1
      attr['strf'] = "%Y-%m"
    when 2
      attr['strf'] = "%F"
    else
      ""
    end
    if attr['value'][0] == attr['value'][1]
      Time.at(attr['value'][0]).strftime(attr['strf'])
    else
      "#{Time.at(attr['value'][0]).strftime(attr['strf'])} ~ #{Time.at(attr['value'][1]).strftime(attr['strf'])}"
    end if attr['value'].present?
  end

  def attr_address(attr)
    QuillCommon::AddressUtility.find_province_city_town_by_code attr['value']
  end

  def attr_array(attr)
    if attr['element_type'].to_i == 7
      "error"
    else
      attr['type'] = attr['element_type']
      attr_tag(attr)
    end
  end
end
