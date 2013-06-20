class Gift
	include Mongoid::Document
	include Mongoid::Timestamps

	# 1 off the shelf, 2 on the shelf, 4 deleted
	field :status, :type => Integer, default: 1
	# 1 for one virtual gift, 2 for virtual gift whose number can be selected, 4 for real gift
	field :type, :type => Integer, default: 1
	field :title, :type => String, default: ""
	field :description, :type => String, default: ""
	field :quantity, :type => Integer, default: 0
	field :point, :type => Integer, default: 0

	has_one :material

	default_scope order_by(:created_at.desc)

	scope :normal, where(:status => 1)
	scope :virtual, normal.where(:type.in => [1,2])
	scope :virtual_one, normal.where(:type => 1)
	scope :virtual_multiple, normal.where(:type => 2)
	scope :real, normal.where(:type => 4)

	index({ type: 1, status: 1 }, { background: true } )

	def find_by_id(gift_id)
		return self.normal.
	end
end
