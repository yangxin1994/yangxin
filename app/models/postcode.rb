# coding: utf-8

class Postcode
	include Mongoid::Document

	field :country, :type => String, :default => ""
	field :province, :type => String, :default =>""
	field :city, :type => String, :default => ""
	field :postcode, :type => String, :default => ""

	has_many :ip_infos

	#--
	# instance methods
	#++

	def to_i
		return postcode.to_i
	rescue
		return ErrorEnum::UNKNOWN_ERROR
	end

	def to_s
		JSON.parse(self.to_json)
	end
end