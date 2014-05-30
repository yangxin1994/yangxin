# encoding: utf-8
class CarnivalPrize

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  field :name, type: String, default: ""
  field :amount, type: Integer
  field :remain, type: Integer

  has_many :carnival_orders


  def self.draw
    tot_number = (self.all.map { |e| e.amount }).sum
    p = tot_number * 1.0 / 20000
    return nil if rand > p
    v = rand
    p1 = CarnivalPrize.where(name: "红米note").first
    p2 = CarnivalPrize.where(name: "小米盒子").first
    p3 = CarnivalPrize.where(name: "小米移动电源").first
    if v < 2.0 / 27 && p1.remain > 0
      p1.remain = p1.remain - 1
      p1.save
      return p1
    end
    if v < 7.0 / 27 && p2.remain > 0
      p2.remain = p2.remain - 1
      p2.save
      return p2
    end
    if p3.remain > 0
      p3.remain = p3.remain - 1
      p3.save
      return p3
    end
    return nil
  end

  def self.generate_data
    return -1 if CarnivalPrize.all.length > 0
    CarnivalPrize.create(name: "红米note", amount: 2, remain: 2)
    CarnivalPrize.create(name: "小米盒子", amount: 5, remain: 5)
    CarnivalPrize.create(name: "小米移动电源", amount: 20, remain: 20)
  end

  def self.clear_data
    CarnivalPrize.destroy_all
  end
end
