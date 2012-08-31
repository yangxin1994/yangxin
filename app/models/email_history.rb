class EmailHistory
  include Mongoid::Document
  include Mongoid::Timestamps
	field :success, :type => Boolean
	belongs_to :user
	belongs_to :survey
end
