class Present < BasicPresent

	field :point, :type => Integer
	
	has_many :orders, :class_name => "Order"
	has_many :materials, :as => :materials
	
	scope :expired, where( :status => 0)
	# TO DO Validation
	validates_presence_of :point
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
