class Award < BasicPresent
	extend Mongoid::FindHelper
	include Mongoid::Validator
	field :budget, :type => Integer
	# can be 0()
	field :status, :type => Integer, :default => 0
	field :weighting, :type => Integer, :default => 0

	belongs_to :lottery_code
	belongs_to :lottery
	validates_presence_of :type
	validates :budget, :spend => { :size => :big }
end