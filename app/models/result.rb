# encoding: utf-8
require 'error_enum'
require 'tool'
class Result
	include Mongoid::Document
	include Mongoid::Timestamps

	field :filter_name, :type => String
	field :time_params, :type => Hash, default: {"stats" => ["mean"], "segments" => nil}
	field :time_result, :type => Hash
	field :region_result, :type => Hash
	field :channel_result, :type => Hash
	field :source_result, :type => Hash
	field :answers_result, :type => Hash

	belongs_to :survey

	def self.find_by_filter_name(filter_name)
		return Result.where(:filter_name => filter_name).first
	end

	def answers
		answers = self.survey.answers.not_preview.finished
		return answers if self.filter_name == "default"
		filter_conditions = self.survey.filters[self.filter_name]
		filtered_answers = []
		answers.each do |a|
			filtered_answers << a if a.satisfy_conditions(filter_conditions)
		end
		return filtered_answers
	end

	def self.find_or_create_by_filter_name(filter_name)
		result = self.find_by_filter_name(filter_name)
		if result.nil?
			result = self.new(filter_name: filter_name)
			result.refresh
		end
		return result
	end

	def self.refresh_or_create_by_filter_name(filter_name)
		result = self.find_by_filter_name(filter_name)
		result = self.new(filter_name: filter_name) if result.nil?
		result.refresh
		return result
	end

	def refresh
		answers = self.answers
		self.analyze_time(answers)
		self.analyze_channel(answers)
		self.save
	end

	def analyze_channel(answers)
		# get data
		channel_ary = answers.map { |a| a.channel }
		# make stats
		self.channel_result = {}
		channel_ary.each do |channel|
			self.channel_result[channel] = 0 if self.channel_result[channel].nil?
			self.channel_result[channel] = self.channel_result[channel] + 1
		end
	end

	def analyze_time(answers)
		# get data
		time_ary = answers.map { |a| a.finished_at - a.created_at.to_i }
		time_ary.sort!
		# get segment parameters
		segments = self.time_params["segments"]
		if segments.nil?
			segment_num = 5
			min_time = time_ary[0]
			max_time = time_ary[-1]
			interval = (max_time - min_time) - segment_num
			segments = []
			1.upto(segment_num - 1) do |i|
				segments << min_time + i * interval
			end
		end

		# make stats of segment results
		segments << time_ary[-1]
		segments_result = Array(segments.length, 0)
		segment_index = 0
		time_ary.each do |time|
			if time > segments[segment_index]
				segment_index = segment_index + 1
				redo
			end
			segments_result[segment_index] = segments_result[segment_index] + 1
		end
		self.time_result["segments_result"] = segments_result

		# make other stats
		self.time_params["stats"].each do |stat|
			case stat
			when "mean"
				self.time_result["mean"] = time_ary.sum / time_ary.length
			end
		end
	end


	def self.sample_attr_analysis(question, answers, analysis_params)
		# 1. the total answer number and the number of answers that answers this question

	end

	def self.analysis_choice
		
	end

	def self.analysis_matrix_choice
		
	end

	def self.analysis_number
		
	end
end
