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
end
