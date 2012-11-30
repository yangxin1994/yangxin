class BasicGift
	include Mongoid::Document
	include Mongoid::Timestamps
	extend Mongoid::FindHelper
	include Mongoid::ValidationsExt
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
	
	default_scope where(:is_deleted => false ).order_by(:created_at, :desc)

	scope :cash, where( :type => 0)
	scope :entity, where( :type => 1)
	scope :virtual, where( :type => 2)
	scope :lottery, where( :type => 3)
	scope :stockout, where(:surplus.lt => 1)

	before_create :set_surplus
	before_save :make_status , :set_quantity

  def make_status
    self.status = 1 if self.surplus > 0 && self.status == -1 
    self.status = -1 if self.surplus <= 0
  end

  def set_quantity
  	p "aa"
  	if changed_attributes["surplus"]
  		p "========"
  		self.quantity += (changed_attributes["surplus"]- self.surplus)
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