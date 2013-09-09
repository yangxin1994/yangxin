#encoding: utf-8
class BrowserHistory
	include Mongoid::Document
	field :url, :type => String
	field :title, :type => String
	field :last_visit_time, :type => Integer
	field :visit_count, :type => Integer
	field :typed_count, :type => Integer

	belongs_to :browser

	index({ url: 1 }, { background: true } )

	def self.find_by_url(url)
		return self.where(:url => url).first
	end
end
