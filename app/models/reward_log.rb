class RewardLog
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Mongoid::FindHelper
  include Mongoid::ValidationsExt
  # can be 1 (LotteryCode) 2 (Point)
  field :type, :type => Integer
  field :point, :type => Integer, :default => 0
  # can be 0 (AdminOperate), 1 (InviteUser), 2 (FilledSurvey), 3 (ExtendSurvey), 4 (ExchangeGift), 5 (revoke)
  field :cause, :type => Integer
  field :value, :type => Hash

  field :invited_user_id, :type => String
  field :extended_survey_id, :type => String

  scope :point_logs, where( :type => 2)
  scope :lottery_logs, where( :type => 1)

  has_one :lottery_code
  belongs_to :filled_survey, :class_name => "Survey", :inverse_of => :reward_logs
  
  belongs_to :user, :class_name => "User", :inverse_of => :reward_logs
  belongs_to :operator, :class_name => "User", :inverse_of => :operate_reward_logs
  belongs_to :order, :class_name => "Order", :inverse_of => :reward_log

  # TO DO validation
  #validates_presence_of :point, :cause, :operator
  validates :point, :numericality => true
  #validates :invited_user_id, :presence => true
  #validates :user_id, :presence => true

  # before_save :operated_point
  after_create :operate_user_point
 
  def self.revoke_operation(log_id,admin_id)
    p = RewardLog.find(log_id)
    RewardLog.create(:user_id => p.user.id,
                     :point => -p.point,
                     :operator_id => admin_id, 
                     :cause => 4)
  end

  def operate_user_point
    return false if user.blank? && point.blank?
    return true if point == 0
    if self.point + point >= 0
      user.inc(:point, self.point)
    else
      false
    end
  end
end