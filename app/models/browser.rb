#encoding: utf-8
class Browser
	include Mongoid::Document
	field :last_request_time, :type => Integer

	belongs_to :browser_extension

	def self.find_by_id(browser_id)
		return self.where(:_id => browser_id).first
	end

end
