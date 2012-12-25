class InterviewerTask
	include Mongoid::Document 
	include Mongoid::Timestamps

	field :quota, :type => Hash
	# 0(doing), 1(under review), 2(finished)
	field :status, :type => Integer

	belongs_to :survey
	belongs_to :user
	
	has_many :answers

end
