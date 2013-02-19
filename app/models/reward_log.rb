class RewardLog
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Mongoid::FindHelper
  include Mongoid::ValidationsExt
  # can be 1 (LotteryCode) 2 (Point)
  field :type, :type => Integer
  field :point, :type => Integer, :default => 0
  # can be 0 (AdminOperate), 1 (InviteUser), 2 (FilledSurvey), 3 (ExtendSurvey), 4 (ExchangeGift), 5 (revoke), 6 (ExchangeLottery)
  field :cause, :type => Integer
  field :cause_desc, :type => String
  field :value, :type => Hash
  field :ref, :type => String

  scope :point_logs, where( :type => 2).order_by("created_at","desc")
  scope :lottery_logs, where( :type => 1).order_by("created_at","desc")

  has_one :lottery_code
  belongs_to :filled_survey, :class_name => "Survey", :inverse_of => :reward_logs
  
  belongs_to :user, :class_name => "User", :inverse_of => :reward_logs
  belongs_to :operator, :class_name => "User", :inverse_of => :operate_reward_logs
  belongs_to :order, :class_name => "Order", :inverse_of => :reward_log

  # TO DO validation
  # validates_presence_of :point, :cause, :operator
  # validates :point, :numericality => true
  #validates :invited_user_id, :presence => true
  #validates :user_id, :presence => true

  # before_save :operated_point
  after_create :operate_user_point

  def revoke_operation(user, cause_desc)
    RewardLog.create(:user_id => user.id,
                     :point => -self.point,
                     :operator => user,
                     :type => 2,
                     :ref => self._id,
                     :cause_desc => cause_desc,
                     :cause => 5)
  end

  def operate_user_point
    return false if user.blank?
    return true if point == 0
    if((self.point + user.point) >= 0)
      user.inc(:point, self.point)
    else
      self.delete
      false
    end
  end
end
