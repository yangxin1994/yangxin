require 'tool'
class City

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  field :name, :type => String
  field :amount, :type => Integer, default: 0
  field :records, :type => Array, default: []

  belongs_to :client

  def refresh_records
    if self.amount > self.records.length
      cur_len = self.records.length
      cur_len.upto(self.amount-1).each do |index|
        self.records[index] = ["40.017098", "116.222777"]
      end
    else
      self.records = self.records[0..amount-1]
    end
    self.save
  end
end
