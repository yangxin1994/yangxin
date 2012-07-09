class Present
	include Mongoid::Document
	include Mongoid::Timestamps
	field :name, :type => String
	# can be 0 (Cash), 1 (RealGoods), 2 (VirtualGoods), 3 (Lottery), 4 (award)
	field :present_type, :type => Integer
	field :point, :type => Integer
	field :quantity, :type => Integer
	field :image_id, :type => String #TO DO Default
	field :description, :type => String
	field :start_time, :type => Date
	field :end_time, :type => Date
	# can be -1 (has no), 0 (expired), 1 (can be rewarded)
	field :status, :type => Integer, :default => 1
	
	# TO DO Def Scope
	scope :cash_present, where( :type => 0)
	scope :realgoods_present, where( :type => 1)
	scope :virtualgoods_present, where( :type => 2)
	scope :lottery_present, where( :type => 3)
	scope :award_present, where( :type => 4)

	scope :can_be_rewarded, where( :status => 1 ) 
	scope :expired, where( :status => 0 )
	# TO DO Validation
	has_many :orders, :class_name => "Order"
	has_many :materials, :as => :materialable

	attr_accessible :materials
	#validates_presence_of :present_type, :point, :start_time, :end_time
	#validates :name, :presence => true,
	#								 :length => { :maximum => 140 }
	#validates :present_type, :presence => true
	#validates :quantity, :presence => true,
	#										 :numericality => { :greater_than_or_equal_to => 0 }


	# TO DO Filter
	
	# We must follow the Law of Demeter(summed up as "use only one dot"), and here is the code: 


	private
	def auto_expired
		self.status = -1  if quantity < 0 
	end

end
