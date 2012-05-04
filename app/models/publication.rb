class Publication
  include Mongoid::Document
	field :award, :type => Integer
	field :created_at, :type => Integer, default: -> { Time.now.to_i }
	field :updated_at, :type => Integer, default: -> { Time.now.to_i }
	field :expired_at, :type => Integer
	field :publish_time, :type => Integer
	field :filter, :type => Filter

	# one publication belongs to one survey
end
