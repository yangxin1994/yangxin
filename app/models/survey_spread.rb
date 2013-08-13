# encoding: utf-8
require 'error_enum'
class SurveySpread
	include Mongoid::Document
	field :times, :type => Integer, default: 1

	belongs_to :user
	belongs_to :survey

	index({ user_id: 1 }, { background: true } )
	index({ survey_id: 1 }, { background: true } )


	def self.inc(user, survey)
		ss = SurveySpread.where(:user_id => user._id, :survey_id => survey._id)[0]
		if ss.nil?
			ss = SurveySpread.create
			user.survey_spreads << ss
			survey.survey_spreads << ss
		else
			ss.times = ss.times + 1
		end
		ss.save
	end

	def self.surveys_with_spread_hash(user)
		ss_array = user.survey_spreads
	end
end
