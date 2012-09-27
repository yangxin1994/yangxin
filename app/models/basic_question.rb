# coding: utf-8
require 'error_enum'
require 'question_io'
#The question object has the following structure
# {
#  "question_id" : id of the question(string),
#  "question_type" : type of the question(string),
#  "content" : content of the question(string),
#  "note" : note of the question(string),
#  "is_required" : whether the question is required to be answered(bool),
#  other fields are related to question type
# }
#Structure of different type question object can be found at 
# ChoiceQuestion, 
# MatrixChoiceQuestion, 
# TextBlankQuestion, 
# NumberBlankQuestion, 
# EmailBlankQuestion, 
# PhoneBlankQuestion, 
# TimeBlankQuestion, 
# AddressBlankQuestion, 
# BlankQuestion, 
# MatrixBlankQuestion, 
# RankQuestion, 
# SortQuestion, 
# ConstSumQuestion
class BasicQuestion
  extend Mongoid::FindHelper
  include Mongoid::Document
  field :content, :type => Hash, default: {"text" => OOPSDATA["question_default_settings"]["content"], "image" => "", "audio" => "", "video" => ""}
  field :note, :type => String, default: OOPSDATA["question_default_settings"]["note"]
  field :issue, :type => Hash
  field :question_type, :type => Integer

  before_save :clear_question_object
  before_update :clear_question_object
  before_destroy :clear_question_object

  ATTR_NAME_ARY = %w[content note]

  def csv_header(header_prefix)
    q = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{question_type}"] + "Io").new(self)
    q.csv_header(header_prefix)
  end

  def spss_header(header_prefix)
    q = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{question_type}"] + "Io").new(self)
    q.spss_header(header_prefix)
  end

=begin
  # def csv_header(qindex)
  #   retval = []
  #   header_prefix = "q#{qindex}"
  #   input = "-input"
  #   case question_type
  #   ##### CHOICE_QUESTION #####
  #   when QuestionTypeEnum::CHOICE_QUESTION
  #     if issue["max_choice"].to_i > 1
  #       issue["choices"].each_index do |i|
  #         retval << header_prefix + "-c#{i + 1}"
  #       end
  #     else
  #       retval << header_prefix
  #     end
  #     if issue["other_item"]["has_other_item"]
  #       retval << header_prefix + input
  #     end
  #   ##### MATRIX_CHOICE_QUESTION #####
  #   when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
  #     if issue["max_choice"].to_i > 1
  #       issue["row_id"].each_index do |r|
  #         issue["choices"].each_index do |i|
  #           retval << header_prefix  + "-r#{r + 1}" + "-c#{i + 1}"
  #         end
  #       end
  #     else
  #       issue["row_id"].each_index do |r|
  #         retval << header_prefix  + "-r#{r + 1}"
  #       end
  #     end
  #  ##### QuestionTypeEnum::TEXT_BLANK_QUESTION..QuestionTypeEnum::ADDRESS_BLANK_QUESTION #####
  #   when QuestionTypeEnum::TEXT_BLANK_QUESTION..QuestionTypeEnum::ADDRESS_BLANK_QUESTION
  #     retval << header_prefix
  #   ##### BLANK_QUESTION #####
  #   when QuestionTypeEnum::BLANK_QUESTION, QuestionTypeEnum::TABLE_QUESTION
  #     issue["inputs"].each_index do |i|
  #       retval << header_prefix  + "-c#{i + 1}"
  #     end
  #   # ##### MATRIX_BLANK_QUESTION #####
  #   when QuestionTypeEnum::MATRIX_BLANK_QUESTION
  #     issue["row_id"].each_index do |r|
  #       issue["inputs"].each_index do |i|
  #         retval << header_prefix  + "-r#{r + 1}" + "-c#{i + 1}"
  #       end
  #     end
  #   # ##### CONST_SUM_QUESTION #####
  #   when QuestionTypeEnum::CONST_SUM_QUESTION
  #     issue["items"].each_index do |i|
  #       retval << header_prefix + "-c#{i + 1}"
  #     end
  #     if issue["other_item"]["has_other_item"]
  #       retval << header_prefix + input
  #       retval << header_prefix + input + "-value"
  #     end
  #   # ##### SORT_QUESTION #####
  #   when QuestionTypeEnum::SORT_QUESTION
  #     issue["items"].each_index do |i|
  #       retval << header_prefix + "-c#{i + 1}"
  #     end
  #     if issue["other_item"]["has_other_item"]
  #       retval << header_prefix + input
  #       retval << header_prefix + input + "-value"
  #     end
  #   # ##### RANK_QUESTION #####
  #   when QuestionTypeEnum::RANK_QUESTION
  #     issue["items"].each_index do |i|
  #       retval << header_prefix + "-c#{i + 1}"
  #       if issue["items"][i]["has_unknow"]
  #         retval << header_prefix + "-c#{i + 1}" + "-unknow"
  #       end
  #     end
  #     if issue["other_item"]["has_other_item"]
  #       retval << header_prefix + input
  #       retval << header_prefix + input + "-value"
  #     end

  #   # ##### PARAGRAPH #####
  #   # when QuestionTypeEnum::PARAGRAPH
  #   # ##### PARAGRAPH #####
  #   # when QuestionTypeEnum::FILE_QUESTION
  #   # ##### TABLE_QUESTION #####
  #   # when QuestionTypeEnum::TABLE_QUESTION
  #   end
  #   retval
  # end

  ##### spss #####
  
  SPSS_NUMERIC = "Numeric"
  SPSS_STRING = "String"
  SPSS_OPTED = "选中"
  SPSS_NOT_OPTED = "未选中"
  SPSS_ETC = "其它"
  SPSS_UNKOWN = "不清楚"
  def spss_header(qindex)
    retval = []
    header_prefix = "q#{qindex}"
    input = "-input"
    case question_type
    ##### CHOICE_QUESTION #####
    when QuestionTypeEnum::CHOICE_QUESTION
      if issue["max_choice"].to_i > 1
        issue["choices"].each_index do |i|
          retval << {"spss_name" => header_prefix + "-c#{i + 1}",
                     "spss_type" => SPSS_NUMERIC,
                     "spss_label" => issue["choices"][i]["content"]["text"],
                     "spss_value_label" => {:c1 => SPSS_OPTED,
                                            :c2 => SPSS_NOT_OPTED}}
        end
      else
        choices = {}
        issue["choices"].each_index do |i|
          choices["c#{i+1}"] = issue["choices"][i]
        end
        retval << {"spss_name" => header_prefix,
                   "spss_type" => SPSS_NUMERIC,
                   "spss_label" => content["text"],
                   "spss_value_label" => choices }
      end
      if issue["other_item"]["has_other_item"]
        retval << {"spss_name" => header_prefix + input,
                   "spss_type" => SPSS_STRING,
                   "spss_label" => SPSS_ETC}
      end
    ##### MATRIX_CHOICE_QUESTION #####
    when QuestionTypeEnum::MATRIX_CHOICE_QUESTION
      if issue["max_choice"].to_i > 1
        issue["row_id"].each_index do |r|
          issue["choices"].each_index do |i|
            retval << {"spss_name" => header_prefix  + "-r#{r + 1}" + "-c#{i + 1}",
                       "spss_type" => SPSS_NUMERIC,
                       "spss_label" => issue["choices"][i]["content"]["text"],
                       "spss_value_label" => {:c1 => SPSS_OPTED,
                                              :c2 => SPSS_NOT_OPTED}}
          end
        end
      else
        choices = {}
        issue["choices"].each_index do |i|
          choices["c#{i+1}"] = issue["choices"][i]
        end
        issue["row_id"].each_index do |r|
          retval << {"spss_name" => header_prefix + "-r#{r + 1}",
                     "spss_type" => SPSS_NUMERIC,
                     "spss_label" => content["text"],
                     "spss_value_label" => choices }
        end
      end
   ##### QuestionTypeEnum::TEXT_BLANK_QUESTION..QuestionTypeEnum::ADDRESS_BLANK_QUESTION #####
    when QuestionTypeEnum::TEXT_BLANK_QUESTION..QuestionTypeEnum::ADDRESS_BLANK_QUESTION
      retval << {"spss_name" => header_prefix,
                 "spss_type" => SPSS_STRING,
                 "spss_label" => content["text"]}
    ##### BLANK_QUESTION #####
    when QuestionTypeEnum::BLANK_QUESTION, QuestionTypeEnum::TABLE_QUESTION
      issue["inputs"].each_index do |i|
        retval << {"spss_name" => header_prefix + "-c#{i + 1}",
                   "spss_type" => SPSS_STRING,
                   "spss_label" => issue["inputs"][i]["content"]["text"]}
      end
    # # ##### MATRIX_BLANK_QUESTION #####
    when QuestionTypeEnum::MATRIX_BLANK_QUESTION
      issue["row_id"].each_index do |r|
        issue["inputs"].each_index do |i|
          retval << {"spss_name" => header_prefix  + "-r#{r + 1}" + "-c#{i + 1}",
                     "spss_type" => SPSS_STRING,
                     "spss_label" => issue["inputs"][i]["content"]["text"]}
        end
      end
    # ##### CONST_SUM_QUESTION #####
    when QuestionTypeEnum::CONST_SUM_QUESTION
      issue["items"].each_index do |i|
        retval << {"spss_name" => header_prefix + "-c#{i + 1}",
                   "spss_type" => SPSS_STRING,
                   "spss_label" => issue["items"][i]["content"]["text"]}
      end
      if issue["other_item"]["has_other_item"]
        retval << {"spss_name" => header_prefix + input,
                   "spss_type" => SPSS_STRING,
                   "spss_label" => SPSS_ETC}
        retval << {"spss_name" => header_prefix + input+ "-value",
                   "spss_type" => SPSS_STRING,
                   "spss_label" => issue["other_item"]["content"]["text"]}                   
      end
    # ##### SORT_QUESTION #####
    when QuestionTypeEnum::SORT_QUESTION
      issue["items"].each_index do |i|
        #spss_name << header_prefix + "-c#{i + 1}"
        retval << {"spss_name" => header_prefix + "-c#{i + 1}",
                   "spss_type" => SPSS_STRING,
                   "spss_label" => issue["items"][i]["content"]["text"]}        
      end
      if issue["other_item"]["has_other_item"]
        #spss_name << header_prefix + input
        #spss_name << header_prefix + input + "-value"
        retval << {"spss_name" => header_prefix + input,
                   "spss_type" => SPSS_STRING,
                   "spss_label" => SPSS_ETC}
        retval << {"spss_name" => header_prefix + input+ "-value",
                   "spss_type" => SPSS_STRING,
                   "spss_label" => issue["other_item"]["content"]["text"]}   
      end
    # ##### RANK_QUESTION #####
    when QuestionTypeEnum::RANK_QUESTION
      issue["items"].each_index do |i|
        retval << {"spss_name" => header_prefix + "-c#{i + 1}",
                   "spss_type" => SPSS_STRING,
                   "spss_label" => issue["items"][i]["content"]["text"]}          
        if issue["items"][i]["has_unknow"]
          retval << {"spss_name" => header_prefix + "-c#{i + 1}" + "-unknow",
                     "spss_type" => SPSS_STRING,
                     "spss_label" => SPSS_UNKOWN,
                     "spss_value_label" => {:c1 => SPSS_OPTED,
                                            :c2 => SPSS_NOT_OPTED}}  
        end
      end
      if issue["other_item"]["has_other_item"]
        #spss_name << header_prefix + input
        #spss_name << header_prefix + input + "-value"
        retval << {"spss_name" => header_prefix + input,
                   "spss_type" => SPSS_STRING,
                   "spss_label" => SPSS_ETC}
        retval << {"spss_name" => header_prefix + input+ "-value",
                   "spss_type" => SPSS_STRING,
                   "spss_label" => issue["other_item"]["content"]["text"]}  
      end

    # ##### PARAGRAPH #####
    # when QuestionTypeEnum::PARAGRAPH
    # ##### PARAGRAPH #####
    # when QuestionTypeEnum::FILE_QUESTION
    # ##### TABLE_QUESTION #####
    # when QuestionTypeEnum::TABLE_QUESTION
    end
    retval
  end
=end
  def self.has_question_type(question_type)
    begin
      return !Issue::ISSUE_TYPE[question_type].nil?
    rescue
      return false
    end
  end

  #*description*: find the question instance by its id, return nil if the question does not exist
  #
  #*params*:

  #* id of the question required
  #
  #*retval*:
  #* the question instance
  def self.find_by_id(question_id)
    return self.where(:_id => question_id)[0]
  end

  #*description*: judge whether this question is a quality control question
  #
  #*params*:
  #
  #*retval*:
  #* boolean value
  def is_quality_control_question
    return ["objective", "matching"].include?(self.input_prefix)
  end

  #*description*: serialize the current instance into a question object
  #
  #*params*:
  #* the array of names
  #
  #*retval*:
  #* the question object
  def serialize(attr_name_ary)
    question_obj = {}
    question_obj["question_id"] = self._id.to_s
    attr_name_ary.each do |attr_name|
      method_obj = self.method("#{attr_name}".to_sym)
      question_obj[attr_name] = Marshal.load(Marshal.dump(method_obj.call()))
    end
    return question_obj
  end

  #*description*: update the current question instance without generating id for inputs, and without saving (such stuff should be done by methods in subclasses)
  #
  #*params*:
  #* the array of names
  #* the question object
  #
  #*retval*:
  def update_question(attr_name_ary, question_obj)
    attr_name_ary.each do |attr_name|
      next if attr_name == "question_type"
      method_obj = self.method("#{attr_name}=".to_sym)
      method_obj.call(Marshal.load(Marshal.dump(question_obj[attr_name]))) 
    end
  end

  #*description*: get a question object. Will first try to get it from cache. If failed, will get it from database and write cache
  #
  #*params*:
  #* id of the question required
  #
  #*retval*:
  #* the question object: if successfully obtained
  #* ErrorEnum ::QUESTION_NOT_EXIST : if cannot find the question
  def self.get_question_object(question_id)
    question_object = Cache.read(question_id)
    if question_object == nil
      question = Question.find_by_id(question_id)
      return ErrorEnum::QUESTION_NOT_EXIST if question == nil
      question_object = question.serialize
      Cache.write(question_id, question_object)
    end
    return question_object
  end

  #*description*: clear the cached question object corresponding to current instance, usually called when the question is updated, either its meta data, or questions and constrains
  #
  #*params*:
  def clear_question_object
    Cache.write(self._id, nil)
  end


  def clone
    return Marshal.load(Marshal.dump(self))
  end
end
