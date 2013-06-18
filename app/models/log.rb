require 'error_enum'
class Log
	include Mongoid::Document
	include Mongoid::TimeStamps
	# log type, 1 for answering surveys, 2 for lottery, 4 for gift redeem, 8 for point change
	field :type, :type => Integer
	field :data, :type => Hash, default: {}

	scope :lottery_logs, lambda { where(:type => 2) }
	scope :redeem_logs, lambda { where(:type => 4) }
	scope :point_logs, lambda { where(:type => 8) }

	belongs_to :user

	def self.find_by_id(log_id)
		log = Log.where(:_id => log_id).first
		return log
	end

end
