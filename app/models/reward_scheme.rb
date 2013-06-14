# encoding: utf-8

class RewardScheme
	include Mongoid::Document
	include Mongoid::Timestamps

	field :rewards, type: Array, default: []
	field :need_review, type: Boolean, default: false

end
