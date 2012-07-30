class LotteryAward
  include Mongoid::Document

  field :weighting, :type => Integer, :default => 0
  field :start_time, :type => DataTime
  field :end_time, :type => DataTime
  field :surplus, :type => Integer
  field :quantity, :type => Integer
  field :status, :type => Integer, :default => 4

  belongs_to :award
  belongs_to :lottery

  scope :can_be_draw, where => { :status => 0 }

  after_save: make_status

  def make_status
    status = 0
    status += 1 if Time.now >= end_time
    status += 2 if surplus <= 0
    status = 4 if Time.now <= start_time
    self.update_attribute(:status, status)
  end

 end