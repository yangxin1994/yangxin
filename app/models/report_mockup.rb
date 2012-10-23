# encoding: utf-8
require 'error_enum'
require 'array'
require 'tool'
require 'digest/md5'
class ReportMockup
	include Mongoid::Document
	include Mongoid::Timestamps

	field :title, :type => String, default: "未命名"
	field :subtitle, :type => String
	field :header, :type => String
	field :footer, :type => String
	field :author, :type => String
	field :chart_style, :type => Hash, default: {"single_style" => 0, "cross_style" => 2}
	field :components, :type => Array, default: []

	belongs_to :survey


	def self.find_by_id(report_mockup_id)
		return ReportMockup.where(:_id => report_mockup_id).first
	end

	def self.check_and_create_new(survey, report_mockup)
		return ErrorEnum::WRONG_REPORT_MOCKUP_CHART_STYLE if report_mockup["chart_style"].nil?
		report_mockup["chart_style"]["single_style"] = report_mockup["chart_style"]["single_style"].to_i
		report_mockup["chart_style"]["cross_style"] = report_mockup["chart_style"]["cross_style"].to_i
		if !(-1..4).to_a.include?(report_mockup["chart_style"]["single_style"]) || ![-1, 2, 3, 4].to_a.include?(report_mockup["chart_style"]["cross_style"])
			return ErrorEnum::WRONG_REPORT_MOCKUP_CHART_STYLE
		end

		questions = (survey.pages.map { |p| p["questions"] }).flatten
		report_mockup["components"] ||= []
		report_mockup["components"].each do |c|
			c["component_type"] = c["component_type"].to_i
			if c["component_type"] == 0
				return ErrorEnum::QUESTION_NOT_EXIST if !questions.include?(c["value"])
			elsif c["component_type"] == 1
				return ErrorEnum::QUESTION_NOT_EXIST if !questions.include?(c["value"][0]) || !questions.include?(c["value"][1])
			else
				return ErrorEnum::WRONG_REPORT_MOCKUP_COMPONENT_TYPE
			end
		end
		report_mockup = ReportMockup.new(:title => report_mockup["title"],
			:subtitle => report_mockup["subtitle"],
			:header => report_mockup["header"],
			:footer => report_mockup["footer"],
			:author => report_mockup["author"],
			:chart_style => report_mockup["chart_style"],
			:components => report_mockup["components"])
		report_mockup.save
		survey.report_mockups << report_mockup
		survey.save
		return report_mockup
	end

	def update_report_mockup(report_mockup)
		return ErrorEnum::WRONG_REPORT_MOCKUP_CHART_STYLE if report_mockup["chart_style"].nil?
		report_mockup["chart_style"]["single_style"] = report_mockup["chart_style"]["single_style"].to_i
		report_mockup["chart_style"]["cross_style"] = report_mockup["chart_style"]["cross_style"].to_i
		if !(-1..4).to_a.include?(report_mockup["chart_style"]["single_style"]) || ![-1, 2, 3, 4].to_a.include?(report_mockup["chart_style"]["cross_style"])
			return ErrorEnum::WRONG_REPORT_MOCKUP_CHART_STYLE
		end

		questions = (self.survey.pages.map { |p| p["questions"] }).flatten
		report_mockup["components"] ||= []
		report_mockup["components"].each do |c|
			c["component_type"] = c["component_type"].to_i
			if c["component_type"] == 0
				return ErrorEnum::QUESTION_NOT_EXIST if !questions.include?(c["value"])
			elsif c["component_type"] == 1
				return ErrorEnum::QUESTION_NOT_EXIST if !questions.include?(c["value"][0]) || !questions.include?(c["value"][1])
			else
				return ErrorEnum::WRONG_REPORT_MOCKUP_COMPONENT_TYPE
			end
		end
		self.update_attributes(:title => report_mockup["title"],
			:subtitle => report_mockup["subtitle"],
			:header => report_mockup["header"],
			:footer => report_mockup["footer"],
			:author => report_mockup["author"],
			:chart_style => report_mockup["chart_style"],
			:components => report_mockup["components"])
		return self
	end
end
