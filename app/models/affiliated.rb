class Affiliated
	include Mongoid::Document
	include Mongoid::Timestamps
    field :receive_info,:type => Hash, default: {"receiver" => "",
	  "address" => '',
	  "street_info" => '',
	  "mobile" => '',
	  "postcode" => ''
	}

	belongs_to :user, :inverse_of => 'user'
end
