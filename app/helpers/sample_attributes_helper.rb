# encoding: utf-8
module SampleAttributesHelper
  def time_format(ts, precision=0)
    time = Time.at(ts / 1000)
    case precision
    when 0
      time.year
    when 1
      "#{time.year}-#{time.month}"
    when 2
      "#{time.year}-#{time.month}-#{time.day}"
    end
  end

  def attr_type_tag(_type)
    type = ""
    case _type
    when 0
      type = "字符串"
    when 1
      type = "枚举"
    when 2
      type = "数值"
    when 3
      type = "日期"
    when 4
      type = "数值范围"
    when 5
      type = "日期范围"
    when 6
      type = "地址"
    when 7
      type = "数组"
    end
  end
end
