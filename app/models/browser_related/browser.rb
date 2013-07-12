#encoding: utf-8
class Browser
	include Mongoid::Document
	field :last_request_time, :type => Integer

	belongs_to :browser_extension
	has_many :browser_histories

	def self.find_by_id(browser_id)
		return self.where(:_id => browser_id).first
	end

	def update_history(hisotry_array)
		hisotry_array.each do |e|
			existing_record = self.browser_histories.find_by_url(e["url"])
			if existing_record.nil?
				# create a new history record
				self.browser_histories.create(
					:url => e["url"],
					:title => e["title"],
					:last_visit_time => (e["lastVisitTime"]/1000).to_i,
					:visit_count => e["visit_count"].to_i,
					:typed_count => e["typed_count"].to_i)
			else
				# update the existing history record
				existing_record.update_attributes(
					:title => e["title"],
					:last_visit_time => (e["lastVisitTime"]/1000).to_i,
					:visit_count => e["visit_count"].to_i,
					:typed_count => e["typed_count"].to_i)
			end
		end
		return true
	end

	def recommend_surveys(exclude_survey_ids)
		surveys = Survey.normal.where(:status => Survey::PUBLISHED, :browser_extension_promotable => true).desc(:created_at)
		return surveys.map { |s| s.info_for_browser }
	end
end
