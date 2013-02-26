class BasicGift
	include Mongoid::Document
	include Mongoid::Timestamps
	extend Mongoid::FindHelper
	include Mongoid::ValidationsExt
	include Mongoid::CriteriaExt
	
	field :name, :type => String
	# can be 0 (Cash), 1 (RealGoods), 2 (VirtualGoods), 3 (Lottery)
	field :type, :type => Integer
	field :surplus, :type => Integer
	field :quantity, :type => Integer
	field :description, :type => String
	# can be -1 (has no), 0 (expired), 1 (can be rewarded)
	# can be -1 (has no), 0 (expired), 1 (can be draw) 
	field :status, :type => Integer, :default => 0
	field :end_time, :type => Date

	field :is_deleted, :type => Boolean, :default => false
	
	default_scope order_by(:created_at, :desc)

	scope :cash, where( :type => 0).where(:is_deleted => false )
	scope :entity, where( :type => 1).where(:is_deleted => false )
	scope :virtual, where( :type => 2).where(:is_deleted => false )
	scope :lottery, where( :type => 3).where(:is_deleted => false )
	scope :stockout, where(:surplus.lt => 1).where(:is_deleted => false )

	before_create :set_surplus
	before_save :make_status , :set_quantity
	after_save :save_photo

	index({ type: 1, status: 1 }, { background: true } )
	index({ type: 1, is_deleted: 1 }, { background: true } )
	index({ stockout: 1, is_deleted: 1 }, { background: true } )

	def save_photo
		self.photo.save if self.photo
	end

	def make_status
		self.status = 0 if self.surplus > 0 && self.status == -1 
		self.status = -1 if self.surplus <= 0
	end

	def set_quantity
		if changed_attributes["surplus"]
			self.quantity += (self.surplus - changed_attributes["surplus"])
		end
	end

	def add_quantity(n)
		self.update_attribute(:quantity, self.quantity + n)
		self.update_attribute(:surplus, self.surplus + n)
	end

	def delete
		update_attribute(is_deleted, true)
	end

	private 
	def set_surplus
		self.quantity = self.surplus
	end

end
