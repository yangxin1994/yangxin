# encoding: utf-8
class PunishLog < Log
	field :type, :type => Integer,:default => 64

	def self.create_punish_log(sample_id)
		self.create(:user_id => sample_id)
	end
end