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

	field :end_time, :type => Date

	field :is_deleted, :type => Boolean, :default => false
	
	default_scope where(:is_deleted => false ).order_by("created_at","desc")
	# TO DO Def Scope
	scope :cash, where( :type => 0)
	scope :entity, where( :type => 1)
	scope :virtual, where( :type => 2)
	scope :lottery, where( :type => 3)

	scope :stockout, where(:surplus.lt => 1)


	before_create :set_surplus


	def add_quantity(n)
		self.update_attribute(:quantity, self.quantity + n)
		self.update_attribute(:surplus, self.surplus + n)
	end

	def delete
  	update_attribute(is_deleted, true)
	end

	private 
	def set_surplus
		surplus = quantity
	end

end