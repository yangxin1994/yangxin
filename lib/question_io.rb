class QuestionIo
  attr_accessor :content, :issue, :question_type

  def initialize(q)
    @retval = []
    self.content = q.content
    self.issue = q.issue
    self.question_type = q.question_type
  end


  # csv_header
  # spss_header
  # csv_answer
  # spss_answer
  # load_csv_answer
  def csv_header(header_prefix)
    @retval << header_prefix
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
      
end

class AddressBlankQuestionIo < QuestionIo

end

class BlankQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["inputs"].each_index do |i|
      @retval << header_prefix  + "-c#{i + 1}"
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
end

class ParagraphIo < QuestionIo

end

class FileQuestionIo < QuestionIo
  def csv_header(header_prefix)
    issue["inputs"].each_index do |i|
      @retval << header_prefix  + "-c#{i + 1}"
    end
    return @retval
  end
end

class TableQuestionIo < QuestionIo

end