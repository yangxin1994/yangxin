# already tidied up
class Report::Data

    attr_accessor :report_type, :title, :header, :footer, :author_chn, :author_eng, :style
    attr_reader :component_list

    HEADING_1 = 0
    HEADING_2 = 1
    DESCRIPTION = 2
    CHART_DATA = 3

    def initialize(report_type, title, subtitle, header, footer, author_chn, author_eng, style)
        @report_type = report_type.to_s
        @title = title.to_s
        @subtitle = subtitle.to_s
        @header = header.to_s
        @footer = footer.to_s
        @author_chn = author_chn.to_s
        @author_eng = author_eng.to_s
        @style = style.to_s
        @component_list = []
    end

    def serialize
        obj = {}
        obj["report_type"] = self.report_type
        obj["title"] = self.title
        obj["header"] = self.header
        obj["footer"] = self.footer
        obj["author_chn"] = self.author_chn
        obj["author_eng"] = self.author_eng
        obj["style"] = self.style
        obj["component_list"] = self.component_list
        return obj
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
            component.merge!("text" => opt["text"])
        when DESCRIPTION
            component.merge!("text" => opt["text"])
        when CHART_DATA
            component.merge!("chart_data" => opt["chart_data"])
        end
        @component_list << component
    end

    def pop_component
        @component_list.pop
    end
end
