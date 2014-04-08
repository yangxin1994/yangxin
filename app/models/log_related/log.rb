# encoding: utf-8
require 'error_enum'
class Log

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool
  include ViewHelper
  # log type, 1 for answering surveys, 2 for lottery, 4 for gift redeem, 8 for point change, 16 for register, 32 for spread, 64 for punish                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

  field :type, :type => Integer

  belongs_to :user

  scope :lottery_logs, -> { where(:type => 2) }
  scope :redeem_logs, -> { where(:type => 4) }
  scope :point_logs, -> { where(:type => 8) }
  scope :answer_logs, -> {where(:type => 1)}
  scope :special_logs,->(t) {  where(:type => t,:reason.ne => PointLog::IMPORT,:reason.ne => PointLog::ADMIN_OPERATE)}
  scope :spread_logs, -> { where(:type => 32)}
  scope :disciplinal_logs, -> { where(:type => 64)}
  scope :have_user,-> {where(:user_id.ne => nil)}

  index({ created_at:1},{background: true})
  index({ type:1},{background: true})
  index({ user_id:1},{background: true})
  index({ point:1},{background: true})
  index({ type:1, user_id:1, updated_at:-1},{background: true})
  index({ _type:1, created_at:-1},{background: true})
  index({ survey_id:1,_type:1, created_at:-1},{background: true})
  index({ answer_id:1,_type:1, created_at:-1},{background: true})

  after_create :update_reallog

  def self.fresh_logs
    Log.where(:type.in => [2,8,16]).not_in(:reason => [8,64,28])
    return self.where(:type.in => [2,8,16]).not_in(:reason => [PointLog::IMPORT,PointLog::ADMIN_OPERATE,PointLog::REVOKE])
  end

  def self.get_new_logs(limit=5,type=nil)
    logs = Log.fresh_logs.have_user.desc(:created_at).limit(limit) unless type.present?
    if logs
      logs = logs.map do |log|
        log['username'] = log.user.try(:nickname)
        if log.user.present?
          log['avatar'] = log.user.avatar ? log.user.avatar.picture_url : User::DEFAULT_IMG
        else
          log['avatar'] = User::DEFAULT_IMG
        end
        log
      end      
    end
  end

  def self.get_newest_exchange_logs
    logs = self.redeem_logs.have_user.desc(:updated_at).limit(5);
    logs = logs.map{|log| log['username'] = log.user.nickname;log}
  end

  def update_reallog
    times = Log.get_new_logs(5,nil)[1..4].map(&:created_at).map{|create_time| ViewHelper::View.ch_time(create_time)}
    self['username'] = self.user.try(:nickname)
    if [2,8,6].include?(self.type.to_i) && ![PointLog::IMPORT,PointLog::ADMIN_OPERATE,PointLog::REVOKE].include?(self.reason.to_i)
      hash = {}
      new_log =  '<li><div><span class="time">刚刚</span>'
      new_log += ViewHelper::View.user_behavor(self)
      new_log += '</div></li>'
      hash[:log] = new_log
      hash[:other_times] = times
      FayeClient.send("/realogs/new", hash)
    end
  end




end
