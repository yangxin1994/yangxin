class RewardLog
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  # can be 1 (LotteryCode) 2 (Point)
  field :type, :type => Integer
  field :point, :type => Integer, :default => 0

  # can be 0 (AdminOperate), 1 (InviteUser), 2 (FilledSurvey), 3 (ExtendSurvey), 4 (ExchangeGift), 5 (revoke)
  field :cause, :type => Integer

  field :invited_user_id, :type => String
  field :extended_survey_id, :type => String

  has_one :lottery_code
  belongs_to :filled_survey, :class_name => "Survey", :inverse_of => :reward_logs
  belongs_to :user, :class_name => "User", :inverse_of => :reward_logs
  belongs_to :operated_admin, :class_name => "User", :inverse_of => :operate_reward_logs
  belongs_to :order, :class_name => "Order", :inverse_of => :reward_log

  # TO DO validation
  #validates_presence_of :operated_point, :cause, :operated_admin
  validates :operated_point, :numericality => true
  #validates :invited_user_id, :presence => true
  #validates :user_id, :presence => true

  # before_save :operated_point
  after_create :operate_user_point
 
  def self.revoke_operation(log_id,admin_id)
    p = RewardLog.find(log_id)
    RewardLog.create(:user_id => p.user.id,
                    :point => -p.operated_point,
                    :operated_admin_id => admin_id, 
                    :cause => 4)
  end
  private
  def operate_user_point
    return false if user.blank? && operated_point.blank?
    return true if type != 2 || point = 0
    user.inc(:point, self.point)
  end
end