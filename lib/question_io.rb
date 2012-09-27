# coding: utf-8
class QuestionIo
  attr_accessor :content, :issue, :question_type, :origin_id

  def initialize(q)
    @retval = []
    self.content = q.content
    self.issue = q.issue
    self.question_type = q.question_type
    self.origin_id = q.id
  end
  INPUT = "_input"
  VALUE = "_value"
  UNKNOW = "_unkwon"
  SPSS_NUMERIC = "Numeric"
  SPSS_STRING = "String"
  SPSS_OPTED = "选中"
  SPSS_NOT_OPTED = "未选中"
  SPSS_ETC = "其它"
  SPSS_UNKOWN = "不清楚"


  # csv_header
  # spss_header
  # csv_answer
  # spss_answer
  # load_csv_answer
  def csv_header(header_prefix)
    @retval << header_prefix
  end

  def spss_header(header_prefix)
    @retval << {"spss_name" => header_prefix,
                "spss_type" => SPSS_STRING,
                "spss_label" => content["text"]}    
  end

  def answer_content(v)
    clear_retval
    @retval << v
  end
  
  def answer_import(row, header_prefix)
    @retval = row["#{header_prefix}"]
    return { "#{origin_id}" => @retval}
  end

  def clear_retval
    @retval = []
  end
end

class ChoiceQuestionIo < QuestionIo

  def csv_header(header_prefix)
    if issue["max_choice"].to_i > 1
      issue["choices"].each_index do |i|
        @retval << header_prefix + "_c#{i + 1}"
      end
    else
      @retval << header_prefix
    end
    if issue["other_item"]["has_other_item"]
      @retval << header_prefix + INPUT
    end
    return @retval
  end

  def spss_header(header_prefix)
   if issue["max_choice"].to_i > 1
      issue["choices"].each_index do |i|
        @retval << {"spss_name" => header_prefix + "_c#{i + 1}",
                    "spss_type" => SPSS_STRING,
                    "spss_label" => issue["choices"][i]["content"]["text"],
                    "spss_value_labels" => {"1" => SPSS_OPTED,
                                            "0" => SPSS_NOT_OPTED}}
      end
    else
      choices = {}
      issue["choices"].each_index do |i|
        choices["#{i+1}"] = issue["choices"][i]["content"]["text"]
      end
      @retval << {"spss_name" => header_prefix,
                  "spss_type" => SPSS_STRING,
                  "spss_label" => content["text"],
                  "spss_value_labels" => choices }
    end
    if issue["other_item"]["has_other_item"]
      @retval << {"spss_name" => header_prefix + INPUT,
                  "spss_type" => SPSS_STRING,
                  "spss_label" => SPSS_ETC}
    end
    return @retval
  end

  def answer_content(v)
    clear_retval
    if issue["max_choice"].to_i > 1
      issue["choices"].each_index do |i|
        if v["selections"].include?( (i + 1).to_s)
          @retval << "1"
        else
          @retval << "0"
        end
      end
    else
      @retval << (v["selection"].empty? ? nil : v["selection"])
    end
    if issue["other_item"]["has_other_item"]
      @retval << v["text_input"]
    end
    return @retval
  end

  def answer_import(row, header_prefix)
    @retval = {"text_input" => "",
               "selection" => []}
    if issue["max_choice"].to_i > 1
      issue["choices"].each_index do |i|
        @retval["selection"] << (i + 1).to_s if row["#{header_prefix}_c#{i+1}"] == "1"
      end
    else
      @retval["selection"] << row["header_prefix"] if !row["header_prefix"].nil?
    end
    if issue["other_item"]["has_other_item"]
      @retval["text_input"] = row["#{header_prefix}_input"]
    end
    return { "#{origin_id}" => @retval}
  end

end

class MatrixChoiceQuestionIo < QuestionIo
  #TODO 矩阵选择题好多悲剧!!! 看清了 答案的格式是二维数组
  def csv_header(header_prefix)
    if issue["max_choice"].to_i > 1
      issue["row_id"].each_index do |r|
        issue["choices"].each_index do |c|
          @retval << header_prefix  + "_r#{r + 1}" + "_c#{c + 1}"
        end
      end
    else
      issue["row_id"].each_index do |r|
        @retval << header_prefix  + "_r#{r + 1}"
      end
    end
    return @retval 
  end

  def spss_header(header_prefix)
    if issue["max_choice"].to_i > 1
      issue["row_id"].each_index do |r|
        issue["choices"].each_index do |c|
          @retval << {"spss_name" => header_prefix  + "_r#{r + 1}" + "_c#{c + 1}",
                      "spss_type" => SPSS_STRING,
                      "spss_label" => issue["choices"][c]["content"]["text"],
                      "spss_value_labels" => {"1" => SPSS_OPTED,
                                              "0" => SPSS_NOT_OPTED}}
        end
      end
    else
      choices = {}
      issue["choices"].each_index do |i|
        choices["#{i+1}"] = issue["choices"][i]["content"]["text"]
      end
      issue["row_id"].each_index do |r|
        @retval << {"spss_name" => header_prefix + "_r#{r + 1}",
                    "spss_type" => SPSS_STRING,
                    "spss_label" => content["text"],
                    "spss_value_labels" => choices }
      end
    end
    return @retval
  end

  def answer_content(v)
    clear_retval
    clear_retval
    if issue["max_choice"].to_i > 1
      issue["row_id"].each_index do |r|
        issue["choices"].each_index do |c|
          if v[r].include?( (c + 1).to_s)
            @retval << "1"
          else
            @retval << "0"
          end
        end
      end
    else
      issue["row_id"].each_index do |r|
        @retval << v[r]
      end
    end
    return @retval
  end

  def answer_import(row, header_prefix)
    @retval = []
    if issue["max_choice"].to_i > 1
      issue["row_id"].each_index do |r|
        row_choices = []
        issue["choices"].each_index do |c|
          row_choices << (c + 1).to_s if row["#{header_prefix}_r#{r + 1}_c#{c + 1}"] == "1"
        end
        @retval << row_choices
      end
    else
      issue["row_id"].each_index do |r|
        @retval << row["#{header_prefix}_r#{r + 1}"]
      end
    end
    return { "#{origin_id}" => @retval}  
  end

end

class TextBlankQuestionIo < QuestionIo

end

class NumberBlankQuestionIo < QuestionIo
  def spss_header(header_prefix)
    @retval << {"spss_name" => header_prefix,
                "spss_type" => SPSS_NUMERIC,
                "spss_label" => content["text"]}    
  end
end

class EmailBlankQuesionIo < QuestionIo

end

class UrlBlankQuestionIo < QuestionIo

end

class PhoneBlankQuestionIo < QuestionIo

end

class TimeBlankQuestionIo < QuestionIo
  @time_unit = ["年", "月", "周", "天", "时", "分", "秒"]
  # @time_unit = ["Y", "M", "W", "D", "H", "M", "S"]
  def answer_content(v)
    clear_retval
    clear_retval
    # @time_unit.each_with_index do |e, i|
    #   @retval << "#{v[i]}#{e}" if v[i] != 0
    # end
    # return @retval
    @retval << "#{v[0]}年#{v[1]}月#{v[2]}周#{v[3]}天#{v[4]}时#{v[5]}分#{v[6]}秒"
  end

  def answer_import(row, header_prefix)
    # @time_unit.each_with_index do |e, i|
    #   t = row["#{header_prefix}"][2 * i + 1] == e ? row["#{header_prefix}"][2 * i] : 0
    #   @retval << "#{t}#{e}"
    # end
     
    pa=/[^\u0030-\u0040]/
    p row
    @retval = row["#{header_prefix}"].gsub(pa, ',').split(",").collect{|s| s.to_i}
    return { "#{origin_id}" => @retval}
  end
end

class AddressBlankQuestionIo < QuestionIo
  def answer_content(v)
    clear_retval
    @retval << v.join(';')
  end
  def answer_import(row, header_prefix)
     @retval = row["#{header_prefix}"].split(";")
    return { "#{origin_id}" => @retval}
  end
end

class BlankQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["inputs"].each_index do |c|
      @retval << header_prefix  + "_c#{c + 1}"
    end
    return @retval
  end

  def spss_header(header_prefix)
    issue["inputs"].each_index do |i|
      @retval << {"spss_name" => header_prefix + "_c#{i + 1}",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["inputs"][i]["content"]["text"]}
    end
    return @retval   
  end

  def answer_content(v)
    clear_retval
    issue["inputs"].each_index do |i|
      q = Question.new(:content => issue["inputs"][i]["content"],
                       :issue => issue["inputs"][i]["properties"],
                       :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["inputs"][i]["data_type"]}"])
      qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
      @retval += qi.answer_content(v[i])
    end
    return @retval  
  end

  def answer_import(row, header_prefix)
     issue["inputs"].each_index do |i|
      q = Question.new(:content => issue["inputs"][i]["content"],
                       :issue => issue["inputs"][i]["properties"],
                       :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["inputs"][i]["data_type"]}"])
      qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
      @retval << qi.answer_import(row, "#{header_prefix}_c#{i + 1 }").values[0]
    end
    return { "#{origin_id}" => @retval}
  end
end

class MatrixBlankQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["row_id"].each_index do |r|
      issue["inputs"].each_index do |c|
        @retval << header_prefix  + "_r#{r + 1}" + "_c#{c + 1}"
      end
    end
    return @retval
  end

  def spss_header(header_prefix)
    issue["row_id"].each_index do |r|
      issue["inputs"].each_index do |i|
        @retval << {"spss_name" => header_prefix  + "_r#{r + 1}" + "_c#{i + 1}",
                    "spss_type" => SPSS_STRING,
                    "spss_label" => issue["inputs"][i]["content"]["text"]}
      end
    end
    return @retval 
  end

  def answer_content(v)
    clear_retval
    issue["row_id"].each_index do |r|
      issue["inputs"].each_index do |i|
        q = Question.new(:content => issue["inputs"][i]["content"],
                         :issue => issue["inputs"][i]["properties"],
                         :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["inputs"][i]["data_type"]}"])
        qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
        # p "#{r}*#{i}= #{qi}"
        @retval += qi.answer_content(v[r][i])
      end
    end
    return @retval  
  end
  def answer_import(row, header_prefix)
    issue["row_id"].each_index do |r|
      row_content = []
      issue["inputs"].each_index do |i|
        q = Question.new(:content => issue["inputs"][i]["content"],
                         :issue => issue["inputs"][i]["properties"],
                         :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["inputs"][i]["data_type"]}"])
        qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
        row_content << qi.answer_import(row, "#{header_prefix}_r#{r + 1}_c#{i + 1 }").values[0]
      end
      @retval << row_content
    end
    return { "#{origin_id}" => @retval}
  end
end

class ConstSumQuestionIo < QuestionIo

  def csv_header(header_prefix)
    issue["items"].each_index do |i|
      @retval << header_prefix + "_c#{i + 1}"
    end
    if issue["other_item"]["has_other_item"]
      @retval << header_prefix + INPUT
      @retval << header_prefix + INPUT + VALUE
    end
    return @retval
  end

  def spss_header(header_prefix)
    issue["items"].each_index do |i|
      @retval << {"spss_name" => header_prefix + "_c#{i + 1}",
                  "spss_type" => SPSS_NUMERIC,
                  "spss_label" => issue["items"][i]["content"]["text"]}
    end
    if issue["other_item"]["has_other_item"]
      @retval << {"spss_name" => header_prefix + INPUT,
                  "spss_type" => SPSS_STRING,
                  "spss_label" => SPSS_ETC}
      @retval << {"spss_name" => header_prefix + INPUT + VALUE,
                  "spss_type" => SPSS_NUMERIC,
                  "spss_label" => issue["other_item"]["content"]["text"]}                   
    end
    return @retval
  end
  def answer_content(v)
    clear_retval
    v.each do |k, c|
      unless k == "text_input" || k == issue["other_item"]["input_id"]
        @retval << c 
      end
    end
    if issue["other_item"]["has_other_item"]
      @retval << v["text_input"]
      @retval << v[issue["other_item"]["input_id"]]
    end
    return @retval
  end
  def answer_import(row, header_prefix)
    @retval = {}
    issue["items"].each_with_index do |e, i|
      @retval[e["input_id"]] = row["#{header_prefix}_c#{i + 1}"]
    end
    if issue["other_item"]["has_other_item"]
      @retval["text_input"] = row["#{header_prefix + INPUT}"]
      @retval["#{issue["other_item"]["input_id"]}"] = row["#{header_prefix + INPUT + VALUE}"]
    end
    return { "#{origin_id}" => @retval}    
  end
end

class SortQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["items"].each_index do |i|
      @retval << header_prefix + "_c#{i + 1}"
    end
    if issue["other_item"]["has_other_item"]
      @retval << header_prefix + INPUT
      @retval << header_prefix + INPUT + VALUE
    end
    return @retval
  end
  def spss_header(header_prefix)
    issue["items"].each_index do |i|
      #spss_name << header_prefix + "_c#{i + 1}"
      @retval << {"spss_name" => header_prefix + "_c#{i + 1}",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["items"][i]["content"]["text"]}        
    end
    if issue["other_item"]["has_other_item"]
      #spss_name << header_prefix + input
      #spss_name << header_prefix + input + VALUE
      @retval << {"spss_name" => header_prefix + INPUT,
                  "spss_type" => SPSS_STRING,
                  "spss_label" => SPSS_ETC}
      @retval << {"spss_name" => header_prefix + INPUT + VALUE,
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["other_item"]["content"]["text"]}   
    end
    return @retval
  end
  def answer_content(v)
    clear_retval
    v["sort_result"].each_with_index do |e, i|
      if issue["other_item"]["has_other_item"]
        break if i == v["sort_result"].size - 1
      end
      @retval[i] = e
    end

    if issue["other_item"]["has_other_item"]

      @retval << v["text_input"]
      @retval << v["sort_result"][-1] #这句就是个陷阱!!!
    end
    return @retval
  end
  def answer_import(row, header_prefix)
    @retval = {"sort_result" => []}
    issue["items"].each_index do |i|
      @retval["sort_result"] << row["#{header_prefix}_c#{i + 1}"]
    end
    if issue["other_item"]["has_other_item"]
      @retval["text_input"] = row["#{header_prefix}#{INPUT}"]
      @retval["sort_result"] << row["#{header_prefix}#{INPUT+VALUE}"]
    end
    return { "#{origin_id}" => @retval} 
  end
end

class RankQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["items"].each_index do |i|
      @retval << header_prefix + "_c#{i + 1}"
      if issue["items"][i]["has_unknow"]
        @retval << header_prefix + "_c#{i + 1}" + UNKNOW
      end
    end
    if issue["other_item"]["has_other_item"]
      @retval << header_prefix + INPUT
      @retval << header_prefix + INPUT + VALUE
    end
    return @retval
  end
  #TODO spss_value_label
  def spss_header(header_prefix)
    issue["items"].each_index do |i|
      @retval << {"spss_name" => header_prefix + "_c#{i + 1}",
                  "spss_type" => SPSS_NUMERIC,
                  "spss_label" => issue["items"][i]["content"]["text"]}          
      if issue["items"][i]["has_unknow"]
        @retval << {"spss_name" => header_prefix + "_c#{i + 1}" + UNKNOW,
                    "spss_type" => SPSS_STRING,
                    "spss_label" => SPSS_UNKOWN
                    }  
      end
    end
    if issue["other_item"]["has_other_item"]
      @retval << {"spss_name" => header_prefix + INPUT,
                  "spss_type" => SPSS_STRING,
                  "spss_label" => SPSS_ETC}
      @retval << {"spss_name" => header_prefix + INPUT + VALUE,
                  "spss_type" => SPSS_NUMERIC,
                  "spss_label" => issue["other_item"]["content"]["text"]}  
    end
    return @retval
  end
  def answer_content(v)
    clear_retval
    issue["items"].each do |e|
      @retval << v[e["input_id"]]
      @retval << (v[e["input_id"]] == -1 ? 1 : 0 ) if e["has_unknow"]
    end
    if issue["other_item"]["has_other_item"]
      @retval << v["text_input"]
      @retval << v[issue["other_item"]["input_id"]]
    end
    return @retval
  end
  def answer_import(row, header_prefix)
    @retval = {}
    issue["items"].each_with_index do |e, i|
      @retval["#{e["input_id"]}"] = row["#{header_prefix}_c#{i + 1}"]
    end
    if issue["other_item"]["has_other_item"]
      @retval["text_input"] = row["#{header_prefix + INPUT}"]
      @retval["#{issue["other_item"]["input_id"]}"] = row["#{header_prefix + INPUT + VALUE}"]
    end
    return { "#{origin_id}" => @retval} 
  end
end

class ParagraphIo < QuestionIo

end

class FileQuestionIo < QuestionIo

end

class TableQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["inputs"].each_index do |i|
      @retval << header_prefix  + "_c#{i + 1}"
    end
    return @retval
  end
  def spss_header(header_prefix)
    issue["inputs"].each_index do |i|
      @retval << {"spss_name" => header_prefix + "_c#{i + 1}",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["inputs"][i]["content"]["text"]}
    end
    return @retval   
  end
  def answer_content(v)
    clear_retval
    issue["inputs"].each_index do |i|
      q = Question.new(:content => issue["inputs"][i]["content"],
                       :issue => issue["inputs"][i]["properties"],
                       :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["inputs"][i]["data_type"]}"])
      qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
      @retval += qi.answer_content(v[i])
    end
    return @retval  
  end
  def answer_import(row, header_prefix)
     issue["inputs"].each_index do |i|
      q = Question.new(:content => issue["inputs"][i]["content"],
                       :issue => issue["inputs"][i]["properties"],
                       :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["inputs"][i]["data_type"]}"])
      qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
      @retval << qi.answer_import(row, "#{header_prefix}_c#{i + 1 }").values[0]
    end
    return {"#{origin_id}" => @retval}   
  end
end