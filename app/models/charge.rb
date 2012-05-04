class Charge
  include Mongoid::Document
	field :owner_email, :type => String
	field :value, :type => Integer
	field :method, :type => Integer
	field :status, :type => Integer
	field :created_at, :type => Integer, default: -> { Time.now.to_i }
	field :updated_at, :type => Integer
	# obtain charges of one owner user
	scope :charges_of, lambda { |owner_email| where(:owner_email => owner_email) }

	before_save :set_updated_at
	before_update :set_updated_at

	private
	def set_updated_at
		self.updated_at = Time.now.to_i
	end

end
