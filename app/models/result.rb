# encoding: utf-8
require 'error_enum'
require 'array'
require 'tool'
class Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :result_key, :type => String
	field :finished, :type => Boolean, default: false

	belongs_to :survey

	def self.find_by_result_key(result_key)
		return Result.where(:result_key => result_key).first
	end

	def self.answers(survey, filter_index, include_screened_answer)
		answers = include_screened_answer.to_s == "true" ? survey.answers.not_preview.finished_and_screened : survey.answers.not_preview.finished
		return answers if filter_index == -1
		filter_conditions = survey.filters[filter_index]["conditions"]
		filtered_answers = []
		answers.each do |a|
			filtered_answers << a if a.satisfy_conditions(filter_conditions)
		end
		return filtered_answers
	end
end