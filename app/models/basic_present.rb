class BasicPresent
	include Mongoid::Document
	include Mongoid::Timestamps
	extend Mongoid::FindHelper
	field :name, :type => String
	# can be 0 (Cash), 1 (RealGoods), 2 (VirtualGoods), 3 (Lottery)
	field :type, :type => Integer
	field :surplus, :type => Integer
	field :quantity, :type => Integer
	field :description, :type => String

	field :end_time, :type => Date

	field :is_deleted, :type => Boolean, :default => false
	
	default_scope where(:is_deleted => false)
	# TO DO Def Scope
	scope :cash, where( :type => 0)
	scope :realgoods, where( :type => 1)
	scope :virtualgoods, where( :type => 2)
	scope :lottery, where( :type => 3)
	#scope :award, where( :type => 4)

	scope :stockout, where(:surplus.lt => 1)


	def add_quantity(n)
		self.update_attribute(:quantity, self.quantity + n)
		self.update_attribute(:surplus, self.surplus + n)
	end

	def delete
  	update_attribute(is_deleted, true)
	end

end