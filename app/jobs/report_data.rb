# encoding: utf-8
module Jobs
	class ReportData

		attr_accessor :report_type, :title, :header, :footer, :author_chn, :author_eng, :style
		attr_reader :component_list

		HEADING_1 = 0
		HEADING_2 = 1
		DESCRIPTION = 2
		CHART_DATA = 3

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

		def push_chart_components(component_ary)
			component_ary.each do |c|
				@component_list << {"component_type" => CHART_DATA, "chart_data" => c}
			end
		end

		def push_component(component_type, opt = {})
			component = {"component_type" => component_type}
			case component_type
			when HEADING_1
				component.merge!("text" => opt["text"])
			when HEADING_2
				puts "bbbbb"
				component.merge!("text" => opt["text"])
				puts "ccccc"
				puts component.inspect
			when DESCRIPTION
				component.merge!("text" => opt["text"])
			when CHART_DATA
				component.merge!("chart_data" => opt["chart_data"])
			end
			puts "ddddd"
			@component_list << component
			puts "eeeee"
		end

		def pop_component
			@component_list.pop
		end
	end
end