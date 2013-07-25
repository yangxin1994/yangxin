require 'error_enum'
class Log
	include Mongoid::Document
	include Mongoid::Timestamps
	# log type, 1 for answering surveys, 2 for lottery, 4 for gift redeem, 8 for point change

	field :type, :type => Integer
	# field :data, :type => Hash, default: {}

	scope :lottery_logs, lambda { where(:type => 2) }
	scope :redeem_logs, lambda { where(:type => 4) }
	scope :point_logs, lambda { where(:type => 8) }
	scope :answer_logs, lambda {where(:type => 1)}
	scope :special_logs,lambda { |t| where(:type => t)}
	scope :fresh_logs, lambda { where(:type.ne => 8,:type.ne => 64)}
	scope :disciplinal_logs, lambda { where(:type => 64)}

	belongs_to :user

	def self.find_by_id(log_id)
		log = Log.where(:_id => log_id).first
		return log
	end

	def self.get_new_logs(limit=5,type=nil)
		if type.present?
			@logs = Log.special_logs(type).desc(:created_at).limit(limit)
		else
			@logs = Log.fresh_logs.desc(:created_at).limit(limit)
		end
    	@logs = @logs.map{|log| log['username'] = log.user.try(:nickname);log['avatar'] = log.user.avatar? ? user.avatar.picture_url : nil;log}
	end

	def self.get_newst_exchange_logs
		logs = self.redeem_logs.desc(:updated_at).limit(5);
		@logs = logs.map{|log| log['username'] = log.user.nickname;log}
	end
end