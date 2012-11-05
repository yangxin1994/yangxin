# encoding: utf-8
require 'error_enum'
require 'array'
require 'digest/md5'
class ReportMockup
	include Mongoid::Document
	include Mongoid::Timestamps

	field :title, :type => String, default: "未命名"
	field :subtitle, :type => String
	field :header, :type => String
	field :footer, :type => String
	field :author, :type => String
	field :components, :type => Array, default: []

	belongs_to :survey


	def self.find_by_id(report_mockup_id)
		return ReportMockup.where(:_id => report_mockup_id).first
	end

	def self.check_and_create_new(survey, report_mockup)
		questions = (survey.pages.map { |p| p["questions"] }).flatten
		report_mockup["components"] ||= []
		report_mockup["components"].each do |c|
			c["component_type"] = c["component_type"].to_i
			if c["component_type"] == 0
				return ErrorEnum::QUESTION_NOT_EXIST if !questions.include?(c["value"]["id"])
			elsif c["component_type"] == 1
				return ErrorEnum::QUESTION_NOT_EXIST if !questions.include?(c["value"]["id"]) || !questions.include?(c["value"]["target"]["id"])
			else
				return ErrorEnum::WRONG_REPORT_MOCKUP_COMPONENT_TYPE
			end
			c["chart_style"] = c["chart_style"].to_i
			return ErrorEnum::WRONG_REPORT_MOCKUP_CHART_STYLE if !(-1..4).to_a.include?(c["chart_style"])
		end
		report_mockup = ReportMockup.new(:title => report_mockup["title"],
			:subtitle => report_mockup["subtitle"],
			:header => report_mockup["header"],
			:footer => report_mockup["footer"],
			:author => report_mockup["author"],
			:components => report_mockup["components"])
		report_mockup.save
		survey.report_mockups << report_mockup
		survey.save
		return report_mockup
	end

	def update_report_mockup(report_mockup)
		questions = (self.survey.pages.map { |p| p["questions"] }).flatten
		report_mockup["components"] ||= []
		report_mockup["components"].each do |c|
			c["component_type"] = c["component_type"].to_i
			if c["component_type"] == 0
				return ErrorEnum::QUESTION_NOT_EXIST if !questions.include?(c["value"]["id"])
			elsif c["component_type"] == 1
				return ErrorEnum::QUESTION_NOT_EXIST if !questions.include?(c["value"]["id"]) || !questions.include?(c["value"]["target"]["id"])
			else
				return ErrorEnum::WRONG_REPORT_MOCKUP_COMPONENT_TYPE
			end
			c["chart_style"] = c["chart_style"].to_i
			return ErrorEnum::WRONG_REPORT_MOCKUP_CHART_STYLE if !(-1..4).to_a.include?(c["chart_style"])
		end
		self.update_attributes(:title => report_mockup["title"],
			:subtitle => report_mockup["subtitle"],
			:header => report_mockup["header"],
			:footer => report_mockup["footer"],
			:author => report_mockup["author"],
			:components => report_mockup["components"])
		return self
	end
end
