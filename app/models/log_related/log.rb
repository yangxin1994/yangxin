#already tidied up
require 'error_enum'
class Log
  include Mongoid::Document
  include Mongoid::Timestamps
  # log type, 1 for answering surveys, 2 for lottery, 4 for gift redeem, 8 for point change, 16 for register, 32 for spread, 64 for punish                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

  field :type, :type => Integer
  scope :lottery_logs, lambda { where(:type => 2) }
  scope :redeem_logs, lambda { where(:type => 4) }
  scope :point_logs, lambda { where(:type => 8) }
  scope :answer_logs, lambda {where(:type => 1)}
  scope :special_logs,lambda { |t| where(:type => t)}
  scope :spread_logs, lambda { where(:type => 32)}
  scope :disciplinal_logs, lambda { where(:type => 64)}
  scope :have_user,lambda {where(:user_id.ne => nil)}



  belongs_to :user

  index({ created_at:1},{background: true})
  index({ type:1},{background: true})
  index({ user_id:1},{background: true})
  index({ point:1},{background: true})
  index({ type:1, user_id:1, updated_at:-1},{background: true})
  index({ _type:1, created_at:-1},{background: true})
  index({ survey_id:1,_type:1, created_at:-1},{background: true})
  index({ answer_id:1,_type:1, created_at:-1},{background: true})

  def self.find_by_id(log_id)
    log = Log.where(:_id => log_id).first
    return log
  end

  def self.fresh_logs
    return self.where(:type.in => [2,8,16], :reason.ne => PointLog::IMPORT)
  end

  def self.get_new_logs(limit=5,type=nil)
    @logs = Log.special_logs(type).have_user.desc(:created_at).limit(limit) if type.present?
    @logs = Log.fresh_logs.have_user.desc(:created_at).limit(limit) unless @logs.present?
    if @logs
      @logs = @logs.map do |log|
        log['username'] = log.user.try(:nickname)
        log['avatar'] = log.user.avatar ? log.user.avatar.picture_url : User::DEFAULT_IMG
        log
      end      
    end
  end

  def self.get_newest_exchange_logs
    logs = self.redeem_logs.have_user.desc(:updated_at).limit(5);
    @logs = logs.map{|log| log['username'] = log.user.nickname;log}
  end
end
