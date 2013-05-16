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

	def recommend_surveys_without_reward(exclude_survey_ids)
		survey_ids = (Survey.normal.where(:reward => 0, :publish_status => 8, :show_in_community => true)).map { |e| e._id.to_s }
		survey_ids = survey_ids - exclude_survey_ids
		survey_ids = survey_ids[0..9] if survey_ids.length > 10
		return survey_ids
	end

	def recommend_surveys_with_reward(exclude_survey_ids)
		point_survey_ids = (Survey.normal.in_community.where(:reward => 2, :publish_status => 8, :show_in_community => true)).map { |e| e._id.to_s }
		point_survey_ids = point_survey_ids - exclude_survey_ids
		point_survey_ids = point_survey_ids[0..9] if point_survey_ids.length > 5
		lottery_survey_ids = (Survey.normal.in_community.where(:reward => 1, :publish_status => 8, :show_in_community => true)).map { |e| e._id.to_s }
		lottery_survey_ids = lottery_survey_ids - exclude_survey_ids
		lottery_survey_ids = lottery_survey_ids[0..9] if lottery_survey_ids.length > 5
		return {
			:point => point_survey_ids,
			:lottery => lottery_survey_ids }
	end
end
