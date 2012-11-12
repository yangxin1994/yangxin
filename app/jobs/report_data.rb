# encoding: utf-8
module Jobs
	class ReportData

		attr_accessor :report_type, :title, :header, :footer, :author_chn, :author_eng, :style
		attr_reader :component_list

		def initialize(report_type, title, subtitle, header, footer, author_chn, author_eng, style)
			@report_type = report_type
			@title = title
			@subtitle = subtitle
			@header = header
			@footer = footer
			@author_chn = author_chn
			@author_eng = author_eng
			@style = style
			@component_list = []
		end

		def push_component(component_type, opt = {})
			component = {"component_type" => component_type}
			case component_type
			when 0
				component.merge!("text" => opt["text"])
			when 1
				component.merge!("text" => opt["text"])
			when 2
				component.merge!("text" => opt["text"])
			when 3
				component.merge!("chart_data" => opt["chart_data"])
				
			end
			@component_list << component
		end

		def pop_component
			@component_list.pop
		end
	end
end