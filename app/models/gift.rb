class Gift < BasicGift
	
	field :point, :type => Integer
	# can be -1 (has no), 0 (expired), 1 (can be rewarded)
	field :status, :type => Integer, :default => 1
	field :start_time, :type => Date
	has_many :orders, :class_name => "Order"
	#has_many :materials, :as => :materials
	
	scope :can_be_rewarded, where( :status => 1) 	
	scope :expired, where( :status => 0)
	# TO DO Validation
	validates_presence_of :point
	validates :name, :presence => true,
						:length => { :maximum => 140 }
	validates :type, :presence => true
	validates :quantity, :presence => true,
											 :numericality => { :greater_than_or_equal_to => 0 }

end
