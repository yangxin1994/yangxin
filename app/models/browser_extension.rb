#encoding: utf-8
class BrowserExtension
	include Mongoid::Document
	include Mongoid::Timestamps

	field :version, :type => String
	field :browser_extension_type, :type => String

	has_many :browsers


	def self.find_by_type(browser_extension_type)
		return self.where(:browser_extension_type => browser_extension_type).first
	end
end
