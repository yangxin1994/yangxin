class Gift < BasicGift

	field :point, :type => Integer
	#field :start_time, :type => Date
	has_many :orders, :class_name => "Order", :inverse_of => 'gift'
	has_one :photo, :class_name => "Material", :inverse_of => 'gift'
	belongs_to :lottery, :class_name => "Lottery", :inverse_of => 'gift'
	scope :can_be_rewarded, where( :status => 1).where(:is_deleted => false )
	scope :expired, where( :status => 0).where(:is_deleted => false )

	# TO DO Validation
	validates_presence_of :point
	validates :name, :presence => true,
						:length => { :maximum => 140 }
	validates :type, :presence => true
	validates :surplus, :presence => true,
											:numericality => { :greater_than_or_equal_to => 0 }
	validates :point, :presence => true,
										:numericality => { :greater_than_or_equal_to => 0 }

	index({ is_deleted: 1, status: 1}, { background: true } )

end