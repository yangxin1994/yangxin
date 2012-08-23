class PointLog
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  field :operated_point, :type => Integer, :default => 0
  # can be 0 (AdminOperate), 1 (InviteUser), 2 (FilledSurvey), 3 (ExtendSurvey), 4 (ExchangePresent), 5 (revoke)
  field :cause, :type => Integer

  field :invited_user_id, :type => String
  field :filled_survey_id, :type => String
  field :extended_survey_id, :type => String
  
  belongs_to :user, :class_name => "User", :inverse_of => :point_logs
  belongs_to :operated_admin, :class_name => "User", :inverse_of => :operate_point_logs
  belongs_to :order, :class_name => "Order", :inverse_of => :point_log

  # TO DO validation
  #validates_presence_of :operated_point, :cause, :operated_admin
  validates :operated_point, :numericality => true
  # before_save :operated_point
  after_create :operate_user_point

  def self.revoke_operation(log_id,admin_id)
    p = PointLog.find(log_id)
    PointLog.create(:user_id => p.user.id,
                :operated_point => -p.operated_point,
                :operated_admin_id => admin_id, 
                :cause => 4)
  end
  private
  def operate_user_point
    return false if user.blank? && operated_point.blank?
    user.inc(:point, self.operated_point)
  end
end