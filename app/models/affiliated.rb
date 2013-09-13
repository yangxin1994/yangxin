#already tidied up
class Affiliated
	include Mongoid::Document
	include Mongoid::Timestamps
		field :receiver_info,:type => Hash, default: {"receiver" => "",
		"address" => -1,
		"street_info" => '',
		"mobile" => '',
		"postcode" => ''
	}

	belongs_to :user, :inverse_of => 'user'
end
