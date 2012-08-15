class LotteryAward
  include Mongoid::Document

  belongs_to :award
  belongs_to :lottery

  scope :can_be_draw, where(:status => 0)

  after_save :make_status

  def make_status
    return unless self.start_time && self.end_time
    status = 0
    status += 1 if Time.now >= end_time
    status += 2 if surplus <= 0
    status = 4 if Time.now <= start_time
    self.update_attribute(:status, status) if status != self.status
  end

 end