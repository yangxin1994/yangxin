# encoding: utf-8
require 'quill_common'
class Report::DataAdapter

    CHART_MATHCING = {
      QuestionTypeEnum::CHOICE_QUESTION => [
        ChartStyleEnum::PIE,
        ChartStyleEnum::DOUGHNUT,
        ChartStyleEnum::LINE,
        ChartStyleEnum::BAR,
        ChartStyleEnum::STACK
      ],
      QuestionTypeEnum::MATRIX_CHOICE_QUESTION => [
        ChartStyleEnum::PIE,
        ChartStyleEnum::DOUGHNUT,
        ChartStyleEnum::LINE,
        ChartStyleEnum::BAR,
        ChartStyleEnum::STACK
      ],
      QuestionTypeEnum::NUMBER_BLANK_QUESTION => [
        ChartStyleEnum::PIE,
        ChartStyleEnum::DOUGHNUT,
        ChartStyleEnum::LINE,
        ChartStyleEnum::BAR,
        ChartStyleEnum::STACK
      ],
      QuestionTypeEnum::TIME_BLANK_QUESTION => [
        ChartStyleEnum::PIE,
        ChartStyleEnum::DOUGHNUT,
        ChartStyleEnum::LINE,
        ChartStyleEnum::BAR,
        ChartStyleEnum::STACK
      ],
      QuestionTypeEnum::ADDRESS_BLANK_QUESTION => [
        ChartStyleEnum::PIE,
        ChartStyleEnum::DOUGHNUT,
        ChartStyleEnum::LINE,
        ChartStyleEnum::BAR,
        ChartStyleEnum::STACK
      ],
      QuestionTypeEnum::BLANK_QUESTION => [
        ChartStyleEnum::PIE,
        ChartStyleEnum::DOUGHNUT,
        ChartStyleEnum::LINE,
        ChartStyleEnum::BAR,
        ChartStyleEnum::STACK
      ],
      QuestionTypeEnum::CONST_SUM_QUESTION => [
        ChartStyleEnum::PIE,
        ChartStyleEnum::DOUGHNUT,
        ChartStyleEnum::LINE,
        ChartStyleEnum::BAR,
        ChartStyleEnum::STACK
      ],
      QuestionTypeEnum::SORT_QUESTION => [
        ChartStyleEnum::PIE,
        ChartStyleEnum::DOUGHNUT,
        ChartStyleEnum::LINE,
        ChartStyleEnum::BAR,
        ChartStyleEnum::STACK
      ],
      QuestionTypeEnum::SCALE_QUESTION => [
        ChartStyleEnum::LINE,
        ChartStyleEnum::BAR,
        ChartStyleEnum::STACK
      ]
    }

    def self.convert_single_data(question_type, analysis_result, issue, chart_style, opt = {})
      # get the type of charts needed to be generated
      chart_styles = []

      if chart_style == -1
        chart_styles = CHART_MATHCING[question_type]
      else
        chart_styles << chart_style if CHART_MATHCING[question_type].include?(chart_style) || chart_style == ChartStyleEnum::TABLE
      end

      case question_type
      when QuestionTypeEnum::CHOICE_QUESTION
          return self.convert_single_choice_data(analysis_result, issue, chart_styles)
      when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
          return self.convert_single_matrix_choice_data(analysis_result, issue, chart_styles)
      when QuestionTypeEnum::NUMBER_BLANK_QUESTION
          return self.convert_single_number_blank_data(analysis_result, issue, chart_styles, opt[:segment] || [])
      when QuestionTypeEnum::TIME_BLANK_QUESTION
          return self.convert_single_time_blank_data(analysis_result, issue, chart_styles, opt[:segment] || [])
      when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
          return self.convert_single_address_blank_data(analysis_result, issue, chart_styles)
      when QuestionTypeEnum::CONST_SUM_QUESTION
          return self.convert_single_const_sum_data(analysis_result, issue, chart_styles)
      when QuestionTypeEnum::SORT_QUESTION
          return self.convert_single_sort_data(analysis_result, issue, chart_styles)
      when QuestionTypeEnum::SCALE_QUESTION
          return self.convert_single_scale_data(analysis_result, issue, chart_styles)
      end
    end

    def self.convert_cross_data(target_question_type, analysis_result, question_issue, target_question_issue, chart_style, opt={})
      # get the type of charts needed to be generated
      chart_styles = []

      if chart_style == -1
          chart_styles = [ChartStyleEnum::LINE, ChartStyleEnum::BAR, ChartStyleEnum::STACK]
      else
          chart_styles << chart_style if [ChartStyleEnum::LINE, ChartStyleEnum::BAR, ChartStyleEnum::STACK, ChartStyleEnum::TABLE].include?(chart_style)
      end

      case target_question_type
      when QuestionTypeEnum::CHOICE_QUESTION
          return self.convert_cross_choice_data(analysis_result, question_issue, target_question_issue, chart_styles)
      when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
          return self.convert_cross_matrix_choice_data(analysis_result, question_issue, target_question_issue, chart_styles)
      when QuestionTypeEnum::ADDRESS_BLANK_QUESTION
          return self.convert_cross_address_blank_data(analysis_result, question_issue, target_question_issue, chart_styles)
      when QuestionTypeEnum::NUMBER_BLANK_QUESTION
          return self.convert_cross_number_blank_data(analysis_result, question_issue, target_question_issue, chart_styles, opt[:segment] || [])
      when QuestionTypeEnum::TIME_BLANK_QUESTION
          return self.convert_cross_time_blank_data(analysis_result, question_issue, target_question_issue, chart_styles, opt[:segment] || [])
      when QuestionTypeEnum::CONST_SUM_QUESTION
          return self.convert_cross_const_sum_data(analysis_result, question_issue, target_question_issue, chart_styles)
      when QuestionTypeEnum::SORT_QUESTION
          return self.convert_cross_sort_data(analysis_result, question_issue, target_question_issue, chart_styles)
      when QuestionTypeEnum::SCALE_QUESTION
          return self.convert_cross_scale_data(analysis_result, question_issue, target_question_issue, chart_styles)
      end
    end

    def self.get_item_id_and_text_array(issue, ids)
      items = issue["items"]
      items << issue["other_item"] if issue["other_item"] && issue["other_item"]["has_other_item"]
      items_text = []
      items_id = []
      ids.each do |id|
        item_text = self.get_item_text_by_id(items, id)
        next if items_text.nil?
        items_text << item_text
        items_id << id
      end
      return [items_id, items_text]
    end

    def self.get_item_text_by_id(items, id)
      ids = id.split(',')
      selected_items = items.select { |e| ids.include?(e["id"].to_s) }
      return nil if selected_items.blank?
      item_text_ary = selected_items.map { |item| item["content"]["text"] }
      item_text = item_text_ary.join('或')
      return item_text
    end

    def self.convert_single_choice_data(analysis_result, issue, chart_styles)
      chart_data = []
      items_id, items_text = *self.get_item_id_and_text_array(issue, analysis_result.keys)
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # multipe categories, one series
          data << ["Categories"] + items_text
          number = items_id.map { |id| analysis_result[id] || 0 }
          data << ["选择人数"] + number
        elsif chart_style == ChartStyleEnum::STACK
          # one category, multiple series
          data << ["Categories", "选择人数"]
          items_id.each_with_index do |id, index|
              data << [items_text[index], analysis_result[id] || 0]
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_cross_choice_data(analysis_result, question_issue, target_question_issue, chart_styles)
      chart_data = []

      items_id = analysis_result[:result].keys
      target_items_id = analysis_result[:result][items_id[0]].keys

      items_id, items_text = *self.get_item_id_and_text_array(question_issue, items_id)
      target_items_id, target_items_text = *self.get_item_id_and_text_array(target_question_issue, target_items_id)

      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # categories correspond to target items, series correspond to items
          data << ["Categories"] + target_items_text
          items_id.each_with_index do |item_id, index|
            number = analysis_result[:result][item_id].values
            next if number.blank?
            data << [items_text[index]] + number
          end
        elsif chart_style == ChartStyleEnum::STACK
          # categories correspond to items, series correspond to target items
          data << ["Categories"] + items_text
          target_items_id.each_with_index do |id, index|
            number = []
            analysis_result[:result].each do |item_id, target_result|
              number << target_result[id.to_s]
            end
            data << [target_items_text[index]] + number
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_single_matrix_choice_data(analysis_result, issue, chart_styles)
      chart_data = []
      issue["rows"].each do |row|
        row_id = row["id"]
        # obtain all the results about this row
        cur_row_analysis_result = analysis_result.select do |k, v|
          k.start_with?(row_id.to_s)
        end
        next if cur_row_analysis_result.blank?
        cur_result_without_row_id = {}
        cur_row_analysis_result.each do |k,v|
          cur_result_without_row_id[k.split('-')[1]] = v
        end
        chart_data = chart_data + convert_single_choice_data(cur_result_without_row_id, issue, chart_styles)
      end
      return chart_data
    end

    def self.convert_cross_matrix_choice_data(analysis_result, question_issue, target_question_issue, chart_styles)
      chart_data = []
      target_question_issue["rows"].each do |row|
        row_id = row["id"]
        cur_result_without_row_id = {}
        cur_result_without_row_id[:answer_number] = analysis_result[:answer_number]
        cur_result = {}
        analysis_result[:result].each do |id, cur_analysis_result|
          cur_result[id] = {}
          cur_row_analysis_result = cur_analysis_result.select do |k, v|
            k.start_with?(row_id.to_s)
          end
          cur_row_analysis_result.each do |k,v|
            cur_result[id][k.split('-')[1]] = v
          end
        end
        cur_result_without_row_id[:result] = cur_result
        chart_data = chart_data + convert_cross_choice_data(cur_result_without_row_id, question_issue, target_question_issue, chart_styles)
      end
      return chart_data
    end

    def self.convert_single_number_blank_data(analysis_result, issue, chart_styles, segments)
      chart_data = []
      histogram = analysis_result["histogram"]
      interval_text_ary = []
      interval_text_ary << "#{segments[0]}以下"
      segments[0..-2].each_with_index do |e, index|
        interval_text_ary << "#{e}到#{segments[index+1]}"
      end
      interval_text_ary << "#{segments[-1]}以上"
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # multipe categories, one series
          data << ["Categories"] + interval_text_ary
          data << ["数量"] + histogram
        elsif chart_style == ChartStyleEnum::STACK
          # one category, multiple series
          data << ["Categories", "数量"]
          interval_text_ary.each_with_index do |text, index|
            data << [text, histogram[index]]
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_cross_number_blank_data(analysis_result, question_issue, target_question_issue, chart_styles, segments)
      chart_data = []

      items_id = analysis_result[:result].keys

      items_id, items_text = *self.get_item_id_and_text_array(question_issue, items_id)
      interval_text_ary = []
      interval_text_ary << "#{segments[0]}以下"
      segments[0..-2].each_with_index do |e, index|
        interval_text_ary << "#{e}到#{segments[index+1]}"
      end
      interval_text_ary << "#{segments[-1]}以上"
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # categories correspond to target items, series correspond to items
          data << ["Categories"] + interval_text_ary
          items_id.each_with_index do |item_id, index|
            number = analysis_result[:result][item_id]["histogram"]
            next if number.blank?
            data << [items_text[index]] + number
          end
        elsif chart_style == ChartStyleEnum::STACK
          # categories correspond to items, series correspond to target items
          data << ["Categories"] + items_text
          interval_text_ary.each_with_index do |interval_text, index|
            number = []
            analysis_result[:result].each do |item_id, target_result|
              number << target_result["histogram"][index]
            end
            data << [interval_text] + number
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_single_time_blank_data(analysis_result, issue, chart_styles, segments)
      chart_data = []
      interval_text_ary = []
      interval_text_ary << ReportResult.convert_time_interval_to_text(issue["format"], nil, segments[0])
      segments[0..-2].each_with_index do |e, index|
        interval_text_ary << ReportResult.convert_time_interval_to_text(issue["format"], e, segments[index+1])
      end
      interval_text_ary << ReportResult.convert_time_interval_to_text(issue["format"], segments[-1], nil)
      histogram = histogram = analysis_result["histogram"]
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # multipe categories, one series
          data << ["Categories"] + interval_text_ary
          data << ["数量"] + histogram
        elsif chart_style == ChartStyleEnum::STACK
          # one category, multiple series
          data << ["Categories", "数量"]
          interval_text_ary.each_with_index do |text, index|
            data << [text, histogram[index]]
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_cross_time_blank_data(analysis_result, question_issue, target_question_issue, chart_styles, segments)
      chart_data = []

      items_id = analysis_result[:result].keys

      items_id, items_text = *self.get_item_id_and_text_array(question_issue, items_id)
      interval_text_ary = []
      interval_text_ary << ReportResult.convert_time_interval_to_text(target_question_issue["format"], nil, segments[0])
      segments[0..-2].each_with_index do |e, index|
        interval_text_ary << ReportResult.convert_time_interval_to_text(target_question_issue["format"], e, segments[index+1])
      end
      interval_text_ary << ReportResult.convert_time_interval_to_text(target_question_issue["format"], segments[-1], nil)
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # categories correspond to target items, series correspond to items
          data << ["Categories"] + interval_text_ary
          items_id.each_with_index do |item_id, index|
            number = analysis_result[:result][item_id]["histogram"]
            next if number.blank?
            data << [items_text[index]] + number
          end
        elsif chart_style == ChartStyleEnum::STACK
          # categories correspond to items, series correspond to target items
          data << ["Categories"] + items_text
          interval_text_ary.each_with_index do |interval_text, index|
            number = []
            analysis_result[:result].each do |item_id, target_result|
              number << target_result["histogram"][index]
            end
            data << [interval_text] + number
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_single_address_blank_data(analysis_result, issue, chart_styles)
      address_text = []
      answer_number = []
      analysis_result.each do |region_code, number|
        number = number[0]
        text = QuillCommon::AddressUtility.find_text_by_code(region_code)
        next if text.blank?
        address_text << text
        answer_number << number
      end
      chart_data = []
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # multipe categories, one series
          data << ["Categories"] + address_text
          data << ["数量"] + answer_number
        elsif chart_style == ChartStyleEnum::STACK
          # one category, multiple series
          data << ["Categories", "数量"]
          address_text.each_with_index do |text, index|
            data << [text, answer_number[index]]
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_cross_address_blank_data(analysis_result, question_issue, target_question_issue, chart_styles)
      chart_data = []

      items_id = analysis_result[:result].keys

      items_id, items_text = *self.get_item_id_and_text_array(question_issue, items_id)
      address_text = []
      region_code = []
      analysis_result[:result].each do |id, cur_result|
        cur_result.each do |code, number|
          next if region_code.include?(code)
          text = QuillCommon::AddressUtility.find_text_by_code(code)
          next if text.blank?
          region_code << code
          address_text << text
        end
      end
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # categories correspond to target items, series correspond to items
          data << ["Categories"] + address_text
          items_id.each_with_index do |item_id, index|
            number = []
            region_code.each do |code|
              number << (analysis_result[:result][item_id][code].nil? ? 0 : analysis_result[:result][item_id][code][0].to_i)
            end
            data << [items_text[index]] + number
          end
        elsif chart_style == ChartStyleEnum::STACK
          # categories correspond to items, series correspond to target items
          data << ["Categories"] + items_text
          region_code.each_with_index do |code, index|
            number = []
            analysis_result[:result].each do |item_id, target_result|
              number << (target_result[code].nil? ? 0 : target_result[code][0].to_i)
            end
            data << [address_text[index]] + number
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_single_const_sum_data(analysis_result, issue, chart_styles)
      chart_data = []
      items_id, items_text = *self.get_item_id_and_text_array(issue, analysis_result.keys)
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT, ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # multipe categories, one series
          data << ["Categories"] + items_text
          score = items_id.map { |id| analysis_result[id] }
          data << ["平均比重"] + score
        elsif chart_style == ChartStyleEnum::STACK
          # one category, multiple series
          data << ["Categories", "平均比重"]
          items_id.each_with_index do |id, index|
            data << [items_text[index], analysis_result[id]]
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_cross_const_sum_data(analysis_result, question_issue, target_question_issue, chart_styles)
      chart_data = []

      items_id = analysis_result[:result].keys
      target_items_id = analysis_result[:result][items_id[0]].keys

      items_id, items_text = *self.get_item_id_and_text_array(question_issue, items_id)
      target_items_id, target_items_text = *self.get_item_id_and_text_array(target_question_issue, target_items_id)
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # categories correspond to target items, series correspond to items
          data << ["Categories"] + target_items_text
          items_id.each_with_index do |item_id, index|
            number = analysis_result[:result][item_id].values
            next if number.blank?
            data << [items_text[index]] + number
          end
        elsif chart_style == ChartStyleEnum::STACK
          # categories correspond to items, series correspond to target items
          data << ["Categories"] + items_text
          target_items_id.each_with_index do |id, index|
            number = []
            analysis_result[:result].each do |item_id, target_result|
              number << target_result[id.to_s]
            end
            data << [target_items_text[index]] + number
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_single_sort_data(analysis_result, issue, chart_styles)
      chart_data = []
      items_id, items_text = *self.get_item_id_and_text_array(issue, analysis_result.keys)
      order_number = (analysis_result.map { |e| e.length }).max
      order_text = []
      1.upto(order_number) do |e|
          order_text << "第#{e}位"
      end
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # multipe categories, one series
          data << ["Categories"] + order_text
          1.upto(order_number) do |e|
            number = Array.new(order_number, 0)
            analysis_result[items_id[e-1]].each_with_index do |e, index|
              number[index] = e
            end
            data << [items_text[e-1]] + number
          end
        elsif chart_style == ChartStyleEnum::STACK
          # one category, multiple series
          data << ["Categories"] + items_text
          1.upto(order_number) do |e|
            order_result = []
            items_id.each do |id|
              order_result << analysis_result[id][e-1] || 0
            end
            data << ["第#{e}位"] + order_result
          end
        elsif [ChartStyleEnum::PIE, ChartStyleEnum::DOUGHNUT].include?(chart_style)
          # the propotion for the first order
          data << ["Categories"] + items_text
          times = items_id.map { |id| analysis_result[id][0] }
          data << ["第1位"] + times
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_cross_sort_data(analysis_result, question_issue, target_question_issue, chart_styles)
      chart_data = []

      items_id = analysis_result[:result].keys
      target_items_id = analysis_result[:result][items_id[0]].keys

      items_id, items_text = *self.get_item_id_and_text_array(question_issue, items_id)
      target_items_id, target_items_text = *self.get_item_id_and_text_array(target_question_issue, target_items_id)
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # categories correspond to target items, series correspond to items
          data << ["Categories"] + target_items_text
          items_id.each_with_index do |item_id, index|
            number = analysis_result[:result][item_id].values.map { |e| e[0]}
            next if number.blank?
            data << [items_text[index]] + number
          end
        elsif chart_style == ChartStyleEnum::STACK
          # categories correspond to items, series correspond to target items
          data << ["Categories"] + items_text
          target_items_id.each_with_index do |id, index|
            number = []
            analysis_result[:result].each do |item_id, target_result|
              number << target_result[id.to_s][0]
            end
            data << [target_items_text[index]] + number
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_single_scale_data(analysis_result, issue, chart_styles)
      chart_data = []
      items_id, items_text = *self.get_item_id_and_text_array(issue, analysis_result.keys)
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # multipe categories, one series
          data << ["Categories"] + items_text
          score = items_id.map { |id| analysis_result[id][1] }
          data << ["分数"] + score
        elsif chart_style == ChartStyleEnum::STACK
          # one category, multiple series
          data << ["Categories", "分数"]
          items_id.each_with_index do |id, index|
            data << [items_text[index], analysis_result[id][1]]
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

    def self.convert_cross_scale_data(analysis_result, question_issue, target_question_issue, chart_styles)
      chart_data = []

      items_id = analysis_result[:result].keys
      target_items_id = analysis_result[:result][items_id[0]].keys

      items_id, items_text = *self.get_item_id_and_text_array(question_issue, items_id)
      target_items_id, target_items_text = *self.get_item_id_and_text_array(target_question_issue, target_items_id)
      chart_styles.each do |chart_style|
        data = []
        if [ChartStyleEnum::BAR, ChartStyleEnum::LINE, ChartStyleEnum::TABLE].include?(chart_style)
          # categories correspond to target items, series correspond to items
          data << ["Categories"] + target_items_text
          items_id.each_with_index do |item_id, index|
            number = analysis_result[:result][item_id].values.map { |e| e[1]}
            next if number.blank?
            data << [items_text[index]] + number
          end
        elsif chart_style == ChartStyleEnum::STACK
          # categories correspond to items, series correspond to target items
          data << ["Categories"] + items_text
          target_items_id.each_with_index do |id, index|
            number = []
            analysis_result[:result].each do |item_id, target_result|
              number << target_result[id.to_s][1]
            end
            data << [target_items_text[index]] + number
          end
        end
        chart_data << [chart_style, data] if !data.blank?
      end
      return chart_data
    end

end
