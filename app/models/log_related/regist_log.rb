# encoding: utf-8
# already tidied up
class RegistLog < Log
	field :type, :type => Integer,:default => 16

	def self.create_regist_log(sample_id)
		self.create(:user_id => sample_id)
	end
end
