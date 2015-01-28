# coding: utf-8
require 'error_enum'
require 'question_io'
class BasicQuestion
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool
  
  ATTR_NAME_ARY = %w[content note]

  field :content, :type => Hash, default: {"text" => OOPSDATA["question_default_settings"]["content"], "image" => [], "audio" => [], "video" => []}
  field :note, :type => String, default: OOPSDATA["question_default_settings"]["note"]
  field :issue, :type => Hash
  field :question_type, :type => Integer

  index({ _id: 1, _type: 1 }, { background: true } )

  def csv_header(header_prefix)
    q = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{question_type}"] + "Io").new(self)
    q.csv_header(header_prefix)
  end

  def spss_header(header_prefix)
    q = Kernel.const_get(QuestionTypeEnum::QUESTION_TYPE_HASH["#{question_type}"] + "Io").new(self)
    q.spss_header(header_prefix)
  end

  def excel_header(header_prefix)
    spss_header(header_prefix).map{|s| s['spss_label']}
  end

  def self.has_question_type(question_type)
    begin
      return !Issue::ISSUE_TYPE[question_type].nil?
    rescue
      return false
    end
  end

  def is_quality_control_question
    return ["objective", "matching"].include?(self.input_prefix)
  end



  def serialize(attr_name_ary)
    question_obj = {}
    question_obj["question_id"] = self._id.to_s
    attr_name_ary.each do |attr_name|
      method_obj = self.method("#{attr_name}".to_sym)
      question_obj[attr_name] = Marshal.load(Marshal.dump(method_obj.call()))
    end
    return question_obj
  end

  def update_question(attr_name_ary, question_obj)
    attr_name_ary.each do |attr_name|
      next if attr_name == "question_type"
      method_obj = self.method("#{attr_name}=".to_sym)
      method_obj.call(Marshal.load(Marshal.dump(question_obj[attr_name]))) 
    end
  end

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



  def remove_hidden_items(items)
    return self
  end

  def type_of(class_name)
    return self.class == class_name
  end


  def clone
    return Marshal.load(Marshal.dump(self))
  end


  def update_items(to_be_removed)
    items = issue["items"]
    sub_questions = issue["items"]
    items.delete_if { |e| to_be_removed["items"].include?(e["id"]) } if !items.nil?
    sub_questions.delete_if { |e| to_be_removed["sub_questions"].include?(e["id"]) } if !sub_questions.nil?
    return self
  end

  def has_other_item
    self.issue["other_item"] && self.issue["other_item"]["has_other_item"] == true  
  end
end
