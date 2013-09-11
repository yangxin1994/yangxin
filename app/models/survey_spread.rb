# encoding: utf-8
# already tidied up
require 'error_enum'
class SurveySpread
	include Mongoid::Document
	include Mongoid::Timestamps
	field :times, :type => Integer, default: 0
	field :survey_creation_time, :type => Integer

	belongs_to :user
	belongs_to :survey

	index({ user_id: 1 }, { background: true } )
	index({ survey_id: 1 }, { background: true } )


	def self.inc(user, survey)
		ss = SurveySpread.where(:user_id => user._id, :survey_id => survey._id)[0]
		if ss.nil?
			ss = SurveySpread.create(:times => 1)
			user.survey_spreads << ss
			survey.survey_spreads << ss
		else
			ss.times = ss.times + 1
		end
		ss.save
	end

	def self.create_new(user, survey)
		ss = SurveySpread.where(:user_id => user._id, :survey_id => survey._id)[0]
		if ss.nil?
			ss = SurveySpread.create(survey_creation_time: survey.created_at.to_i)
			user.survey_spreads << ss
			survey.survey_spreads << ss
		end
		ss.save
	end
end
