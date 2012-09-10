# encoding: utf-8
class QuestionIo
  attr_accessor :content, :issue, :question_type

  def initialize(q)
    @retval = []
    self.content = q.content
    self.issue = q.issue
    self.question_type = q.question_type
  end

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

  def csv_content(v)
    @retval << v
  end
  
end

class ChoiceQuestionIo < QuestionIo

  def csv_header(header_prefix)
    if issue["max_choice"].to_i > 1
      issue["choices"].each_index do |i|
        @retval << header_prefix + "-c#{i + 1}"
      end
    else
      @retval << header_prefix
    end
    if issue["other_item"]["has_other_item"]
      @retval << header_prefix + "-input"
    end
    return @retval
  end

  def spss_header(header_prefix)
   if issue["max_choice"].to_i > 1
      issue["choices"].each_index do |i|
        @retval << {"spss_name" => header_prefix + "-c#{i + 1}",
                    "spss_type" => SPSS_NUMERIC,
                    "spss_label" => issue["choices"][i]["content"]["text"],
                    "spss_value_label" => {:c1 => SPSS_OPTED,
                                           :c2 => SPSS_NOT_OPTED}}
      end
    else
      choices = {}
      issue["choices"].each_index do |i|
        choices["c#{i+1}"] = issue["choices"][i]["content"]["text"]
      end
      @retval << {"spss_name" => header_prefix,
                  "spss_type" => SPSS_NUMERIC,
                  "spss_label" => content["text"],
                  "spss_value_label" => choices }
    end
    if issue["other_item"]["has_other_item"]
      @retval << {"spss_name" => header_prefix + "-input",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => SPSS_ETC}
    end
    return @retval
  end

  def csv_content(v)
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
end

class MatrixChoiceQuestionIo < QuestionIo
  def csv_header(header_prefix)
    if issue["max_choice"].to_i > 1
      issue["row_id"].each_index do |r|
        issue["choices"].each_index do |i|
          @retval << header_prefix  + "-r#{r + 1}" + "-c#{i + 1}"
        end
      end
    else
      issue["row_id"].each_index do |r|
        @retval << header_prefix  + "-r#{r + 1}"
      end
    end
    return @retval 
  end
  def spss_header(header_prefix)
    if issue["max_choice"].to_i > 1
      issue["row_id"].each_index do |r|
        issue["choices"].each_index do |i|
          @retval << {"spss_name" => header_prefix  + "-r#{r + 1}" + "-c#{i + 1}",
                      "spss_type" => SPSS_NUMERIC,
                      "spss_label" => issue["choices"][i]["content"]["text"],
                      "spss_value_label" => {:c1 => SPSS_OPTED,
                                             :c2 => SPSS_NOT_OPTED}}
        end
      end
    else
      choices = {}
      issue["choices"].each_index do |i|
        choices["c#{i+1}"] = issue["choices"][i]["content"]["text"]
      end
      issue["row_id"].each_index do |r|
        @retval << {"spss_name" => header_prefix + "-r#{r + 1}",
                    "spss_type" => SPSS_NUMERIC,
                    "spss_label" => content["text"],
                    "spss_value_label" => choices }
      end
    end
    return @retval
  end
  def csv_content(v)
    if issue["max_choice"].to_i > 1
      issue["row_id"].each_index do |r|
        issue["choices"].each_index do |i|
          if v[r].include?( (i + 1).to_s)
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
end

class TextBlankQuestionIo < QuestionIo

end

class NumberBlankQuestionIo < QuestionIo

end

class EmailBlankQuesionIo < QuestionIo

end

class UrlBlankQuestionIo < QuestionIo

end

class PhoneBlankQuestionIo < QuestionIo

end

class TimeBlankQuestionIo < QuestionIo
  def csv_content(v)
    @retval << "#{v[0]}年#{v[1]}月#{v[2]}周#{v[3]}天#{v[4]}时#{v[5]}分#{v[6]}秒"
  end
end

class AddressBlankQuestionIo < QuestionIo
  def csv_content(v)
    @retval << v.join(';')
  end
end

class BlankQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["inputs"].each_index do |i|
      @retval << header_prefix  + "-c#{i + 1}"
    end
    return @retval
  end

  def spss_header(header_prefix)
    issue["inputs"].each_index do |i|
      @retval << {"spss_name" => header_prefix + "-c#{i + 1}",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["inputs"][i]["content"]["text"]}
    end
    return @retval   
  end

  def csv_content(v)
    issue["inputs"].each_index do |i|
      q = Question.new(:content => issue["inputs"][i]["content"],
                       :issue => issue["inputs"][i]["properties"],
                       :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["inputs"][i]["data_type"]}"])
      qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
      @retval += qi.csv_content(v[i])
    end
    return @retval  
  end
end

class MatrixBlankQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["row_id"].each_index do |r|
      issue["inputs"].each_index do |i|
        @retval << header_prefix  + "-r#{r + 1}" + "-c#{i + 1}"
      end
    end
    return @retval
  end
  def spss_header(header_prefix)
    issue["row_id"].each_index do |r|
      issue["inputs"].each_index do |i|
        @retval << {"spss_name" => header_prefix  + "-r#{r + 1}" + "-c#{i + 1}",
                    "spss_type" => SPSS_STRING,
                    "spss_label" => issue["inputs"][i]["content"]["text"]}
      end
    end
    return @retval 
  end
  def csv_content(v)
    issue["row_id"].each_index do |r|
      issue["inputs"].each_index do |i|
        q = Question.new(:content => issue["inputs"][i]["content"],
                         :issue => issue["inputs"][i]["properties"],
                         :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["inputs"][i]["data_type"]}"])
        qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
        @retval += qi.csv_content(v[i])
      end
      return @retval  
    end
  end
end

class ConstSumQuestionIo < QuestionIo

  def csv_header(header_prefix)
    issue["items"].each_index do |i|
      @retval << header_prefix + "-c#{i + 1}"
    end
    if issue["other_item"]["has_other_item"]
      @retval << header_prefix + "-input"
      @retval << header_prefix + "-input" + "-value"
    end
    return @retval
  end

  def spss_header(header_prefix)
    issue["items"].each_index do |i|
      @retval << {"spss_name" => header_prefix + "-c#{i + 1}",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["items"][i]["content"]["text"]}
    end
    if issue["other_item"]["has_other_item"]
      @retval << {"spss_name" => header_prefix + "-input",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => SPSS_ETC}
      @retval << {"spss_name" => header_prefix + "-input" + "-value",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["other_item"]["content"]["text"]}                   
    end
    return @retval
  end
  def csv_content(v)
    return @retval
  end
end

class SortQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["items"].each_index do |i|
      @retval << header_prefix + "-c#{i + 1}"
    end
    if issue["other_item"]["has_other_item"]
      @retval << header_prefix + "-input"
      @retval << header_prefix + "-input" + "-value"
    end
    return @retval
  end
  def spss_header(header_prefix)
    issue["items"].each_index do |i|
      #spss_name << header_prefix + "-c#{i + 1}"
      @retval << {"spss_name" => header_prefix + "-c#{i + 1}",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["items"][i]["content"]["text"]}        
    end
    if issue["other_item"]["has_other_item"]
      #spss_name << header_prefix + input
      #spss_name << header_prefix + input + "-value"
      @retval << {"spss_name" => header_prefix + "-input",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => SPSS_ETC}
      @retval << {"spss_name" => header_prefix + "-input" + "-value",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["other_item"]["content"]["text"]}   
    end
    return @retval
  end
end

class RankQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["items"].each_index do |i|
      @retval << header_prefix + "-c#{i + 1}"
      if issue["items"][i]["has_unknow"]
        @retval << header_prefix + "-c#{i + 1}" + "-unknow"
      end
    end
    if issue["other_item"]["has_other_item"]
      @retval << header_prefix + "-input"
      @retval << header_prefix + "-input" + "-value"
    end
    return @retval
  end
  def spss_header(header_prefix)
    issue["items"].each_index do |i|
      @retval << {"spss_name" => header_prefix + "-c#{i + 1}",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["items"][i]["content"]["text"]}          
      if issue["items"][i]["has_unknow"]
        @retval << {"spss_name" => header_prefix + "-c#{i + 1}" + "-unknow",
                    "spss_type" => SPSS_STRING,
                    "spss_label" => SPSS_UNKOWN,
                    "spss_value_label" => {:c1 => SPSS_OPTED,
                                          :c2 => SPSS_NOT_OPTED}}  
      end
    end
    if issue["other_item"]["has_other_item"]
      #spss_name << header_prefix + input
      #spss_name << header_prefix + input + "-value"
      @retval << {"spss_name" => header_prefix + "-input",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => SPSS_ETC}
      @retval << {"spss_name" => header_prefix + "-input" + "-value",
                  "spss_type" => SPSS_STRING,
                  "spss_label" => issue["other_item"]["content"]["text"]}  
    end
    return @retval
  end
end

class ParagraphIo < QuestionIo

end

class FileQuestionIo < QuestionIo

end

class TableQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["inputs"].each_index do |i|
      @retval << header_prefix  + "-c#{i + 1}"
    end
    return @retval
  end
  def csv_content(v)
    issue["inputs"].each_index do |i|
      q = Question.new(:content => issue["inputs"][i]["content"],
                       :issue => issue["inputs"][i]["properties"],
                       :question_type => QuestionTypeEnum::BLANK_QUESTION_TYPE["#{issue["inputs"][i]["data_type"]}"])
      qi = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{q.question_type}"] + "Io").new(q)
      @retval += qi.csv_content(v[i])
    end
    return @retval  
  end
end