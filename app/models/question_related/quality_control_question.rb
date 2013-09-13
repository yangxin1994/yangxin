# already tidied up
require 'error_enum'
class QualityControlQuestion < BasicQuestion
  include Mongoid::Document
  field :quality_control_type, :type => Integer
  field :is_required, :type => Boolean, default: true
  field :is_first, :type => Boolean, :default => false

  scope :objective_questions, lambda { where(:quality_control_type => 1) }
  scope :matching_questions, lambda { where(:quality_control_type => 2, :is_first=> true) }
  scope :find_by_type, ->(_type) { _type.present? ? where(:quality_control_type => _type).desc(:created_at) : self.desc(:created_at) }

  index({ quality_control_type: 1, is_first: 1 }, { background: true } )

  OBJECTIVE = 1
  MATCHING = 2

  def self.create_quality_control_question(quality_control_type, question_type, question_number, operator)
    return ErrorEnum::UNAUTHORIZED if !operator.is_admin?
    return ErrorEnum::WRONG_QUESTION_TYPE if !self.has_question_type(question_type)
    if quality_control_type == OBJECTIVE
      # create a objective quality control question
      question = QualityControlQuestion.new(quality_control_type: OBJECTIVE, question_type: question_type, issue: Issue.create_issue(question_type).serialize)
      question.save
      return [question, QualityControlQuestionAnswer.create_new([question._id.to_s], quality_control_type, question_type)]
    elsif quality_control_type == MATCHING
      # create a matching quality control question
      matching_questions = []
      is_first = true
      1.upto(question_number.to_i).each do
        if is_first
          question = QualityControlQuestion.new(is_first:true, quality_control_type: MATCHING, question_type: question_type, issue: Issue.create_issue(question_type).serialize)
          is_first=false
        else
          question = QualityControlQuestion.new(quality_control_type: MATCHING, question_type: question_type, issue: Issue.create_issue(question_type).serialize)
        end
        question.save
        matching_questions << question
      end
      questions_id_ary = matching_questions.map {|qs| qs._id.to_s}
      MatchingQuestion.create_matching(questions_id_ary)
      return matching_questions << QualityControlQuestionAnswer.create_new(questions_id_ary, quality_control_type, question_type)
    else
      return ErrorEnum::WRONG_QUALITY_CONTROL_TYPE
    end
  end

  def update_question(question_obj, operator)
    return ErrorEnum::UNAUTHORIZED if !operator.is_admin?
    self.content = question_obj['content']
    self.note = question_obj['note']
    issue = Issue.create_issue(self.question_type, question_obj['issue'])
    return ErrorEnum::WRONG_DATA_TYPE if issue == ErrorEnum::WRONG_DATA_TYPE
    self.issue = issue.serialize
    self.save
    return self
  end

  def self.list_quality_control_question(quality_control_type)
    objective_questions = []
    matching_questions = []
    if quality_control_type & OBJECTIVE > 0
      objective_questions = QualityControlQuestion.objective_questions.to_a
    end
    if quality_control_type & MATCHING > 0
      matching_question_id_groups = MatchingQuestion.matching_question_id_groups
      matching_question_id_groups.each do |group|
        questions_group = []
        group.each do |q_id|
          questions_group << QualityControlQuestion.find_by_id(q_id)
        end
        #questions_group << QualityControlQuestionAnswer.find_by_question_id(group)
        matching_questions << questions_group
      end
    end
    return {"objective_questions" => objective_questions, "matching_questions" => matching_questions}
  end

  def show_quality_control_question
    if self.quality_control_type == OBJECTIVE
      quality_control_answer = QualityControlQuestionAnswer.find_by_question_id(self._id.to_s)
      return [self, quality_control_answer]
    else
      quality_control_answer = QualityControlQuestionAnswer.find_by_question_id(self._id.to_s)
      matching_question_ids = MatchingQuestion.get_matching_question_ids(self._id)
      questions = []
      matching_question_ids.each do |q_id|
        questions << QualityControlQuestion.find_by_id(q_id)
      end
      questions << quality_control_answer
      return questions
    end
  end

  def delete_quality_control_question(operator)
    return ErrorEnum::UNAUTHORIZED if !operator.is_admin?
    matching_question_ids = []
    if self.quality_control_type == OBJECTIVE
      QualityControlQuestionAnswer.destroy_by_question_id([self._id])
      self.destroy
    else
      matching_question_ids = MatchingQuestion.get_matching_question_ids(self._id)
      QualityControlQuestionAnswer.destroy_by_question_id(matching_question_ids)
      matching_question_ids.each do |q_id|
        question = QualityControlQuestion.find_by_id(q_id)
        question.destroy
        matching_question = MatchingQuestion.find_by_question_id(q_id)
        matching_question.destroy
      end
    end
    # delte this quality control question in surveys
    Survey.all.each do |s|
      if s.quality_control_questions_type == 1
        # the survey has quality control questions that are manually inserted
        s.quality_control_questions_ids.delete(self._id.to_s)
        matching_question_ids.each do |q_id|
          s.quality_control_questions_ids.delete(q_id)
        end
        s.save
      end
    end
    return true
  end

  def self.check_quality_control_answer(quality_control_question_id, answer)
    standard_answer = QualityControlQuestionAnswer.find_by_question_id(quality_control_question_id)
    if standard_answer.quality_control_type == 1
      # this is objective quality control question
      question_answer = answer.random_quality_control_answer_content[quality_control_question_id]
      return false if question_answer.nil?
      volunteer_answer = question_answer["selection"]
      case standard_answer.question_type
      when QuestionTypeEnum::CHOICE_QUESTION
        return Tool.check_choice_question_answer(quality_control_question_id,
          question_answer["selection"], 
          standard_answer.answer_content["items"],
          standard_answer.answer_content["fuzzy"])
      else
        return true
      end
    else
      # this is matching quality control question
      # find all the volunteer answers of this group of quality control questions
      matching_question_id_ary = MatchingQuestion.get_matching_question_ids(quality_control_question_id)
      volunteer_answer = []

      # get the selection of the user
      answer.random_quality_control_answer_content.each do |k, v|
        next if !matching_question_id_ary.include?(k)
        next if v.nil?
        # return false if v.nil?
        volunteer_answer = volunteer_answer + v["selection"]
      end


      standard_matching_items = standard_answer.answer_content["matching_items"]
      standard_matching_items.each do |standard_matching_item|
        return true if (volunteer_answer - standard_matching_item).empty?
      end
      return false
    end
  end
end
