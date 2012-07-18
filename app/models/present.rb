class Present
	include Mongoid::Document
	include Mongoid::Timestamps
	field :name, :type => String
	# can be 0 (Cash), 1 (RealGoods), 2 (VirtualGoods), 3 (Lottery)
	field :type, :type => Integer
	#field :is_award, :type => Boolean, :default => false
	field :point, :type => Integer
	field :quantity, :type => Integer
	field :description, :type => String
	field :start_time, :type => Date
	field :end_time, :type => Date
	# can be -1 (has no), 0 (expired), 1 (can be rewarded)
	field :status, :type => Integer, :default => 1
	field :is_deleted, :type => Boolean, :default => false
	
	default_scope where(:is_deleted => false)
	# TO DO Def Scope
	scope :cash, where( :type => 0)
	scope :realgoods, where( :type => 1)
	scope :virtualgoods, where( :type => 2)
	scope :lottery, where( :type => 3)
	#scope :award, where( :type => 4)

	scope :stockout, where(:quantity.lt => 1)
	scope :can_be_rewarded, where( :status => 1) 
	scope :expired, where( :status => 0)
	
	has_many :orders, :class_name => "Order"
	has_many :materials, :as => :materials
	
	# TO DO Validation
	validates_presence_of :point, :start_time, :end_time
	validates :name, :presence => true,
						:length => { :maximum => 140 }
	validates :type, :presence => true
	validates :quantity, :presence => true,
											 :numericality => { :greater_than_or_equal_to => 0 }

	def self.find_by_id(id)
		begin
			retval = self.find(id)
		rescue Mongoid::Errors::DocumentNotFound
			retval = ErrorEnum::PresentNotFound
		rescue BSON::InvalidObjectId
			retval = ErrorEnum::InvalidPresentId
		end
		retval
	end

	# def delete
	# 	begin
	# 		@present = Present.find(params[:id])
	# 	rescue Mongoid::Errors::DocumentNotFound
	# 		format.json { render json: Errors::PresentNotFound } and return
	# 	rescue BSON::InvalidObjectId
	# 		format.json { render json: ErrorEnum::InvalidPresentId } and return
	# 	end
	# 		@present.is_deleted = true
	# 		format.json { render json: @present.save }
	# end

end
