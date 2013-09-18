module SurveyComponents::SurveyLogicControl
  extend ActiveSupport::Concern

  included do
    field :logic_control, :type => Array, default: []
  end

  SCREEN = 0
  SHOW_QUESTION = 1
  HIDE_QUESTION = 2
  SHOW_ITEM = 3
  HIDE_ITEM = 4
  SHOW_CORRESPONDING_ITEM = 5
  HIDE_CORRESPONDING_ITEM = 6

  RULE_TYPE_ARY = (0..6).to_a


  def show_logic_control
    return Marshal.load(Marshal.dump(self.logic_control))
  end

  def show_logic_control_rule(index)
    return self.logic_control[index.to_i]
  end

  def add_logic_control_rule(rule)
    rule["rule_type"] = rule["rule_type"].to_i
    return ErrorEnum::WRONG_LOGIC_CONTROL_TYPE if !RULE_TYPE_ARY.include?(rule["rule_type"])
    self.logic_control << rule
    self.save
    return self.logic_control
  end

  def update_logic_control_rule(index, rule)
    return ErrorEnum::LOGIC_CONTROL_RULE_NOT_EXIST if self.logic_control.length <= index
    rule["rule_type"] = rule["rule_type"].to_i
    return ErrorEnum::WRONG_LOGIC_CONTROL_TYPE if !RULE_TYPE_ARY.include?(rule["rule_type"])
    self.logic_control[index] = rule
    self.save
    return self.logic_control
  end

  def delete_logic_control_rule(index)
    self.logic_control.delete_at(index)
    self.save
  end

  def clone_logic_control(question_id_mapping)
    self.logic_control.each do |logic_control_rule|
      logic_control_rule["conditions"].each do |condition|
        condition["question_id"] = question_id_mapping[condition["question_id"]]
      end
      if [SHOW_QUESTION, HIDE_QUESTION].include?(logic_control_rule["rule_type"])
        logic_control_rule["result"].each_with_index do |question_id, index|
          logic_control_rule["result"][index] = question_id_mapping[question_id]
        end
      elsif [SHOW_ITEM, HIDE_ITEM].include?(logic_control_rule["rule_type"])
        logic_control_rule["result"].each do |result_ele|
          result_ele["question_id"] = question_id_mapping[result_ele["question_id"]]
        end
      elsif [SHOW_CORRESPONDING_ITEM, HIDE_CORRESPONDING_ITEM].include?(logic_control_rule["rule_type"])
        logic_control_rule["result"]["question_id_1"] = question_id_mapping[logic_control_rule["result"]["question_id_1"]]
        logic_control_rule["result"]["question_id_2"] = question_id_mapping[logic_control_rule["result"]["question_id_2"]]
      end
    end
    self.save
  end

  def adjust_logic_control(question, type)
    rules = self.logic_control
    rules.each_with_index do |rule, rule_index|
      case type
      when 'question_update'
        next if question.issue["items"].nil? && question.issue["rows"].nil?
        item_ids = (question.issue["items"].try(:map) { |i| i["id"] }) || []
        item_ids << question.issue["other_item"]["id"] if question.has_other_item
        row_ids = (question.issue["rows"].try(:map) { |i| i["id"] }) || []
        # first handle conditions
        if question.question_type == 0
          # only choice questions can be conditions for logic control
          if (0..4).to_a.include?(rule["rule_type"])
            rule["conditions"].each do |c|
              next if c["question_id"] != question.id
              # the condition is about the question updated
              # remove the items that do not exist
              c["answer"].delete_if { |item_id| !item_ids.include?(item_id) }
            end
            # if all the items for a condition is removed, remove this condition
            rule["conditions"].delete_if { |c| c["answer"].blank? }
            # if all the conditions for a rule is removed, remove this rule
            if rule["conditions"].blank?
              rules.delete_at(rule_index)
              next
            end
          end
        end
        # then handle result
        if [3,4].to_a.include?(rule["rule_type"])
          rule["result"].each do |r|
            next if r["question_id"] != question.id
            # the result is about the question updated
            # remove the items that do not exist
            r["items"].delete_if { |item_id| !item_ids.include?(item_id) }
            # remove the rows that do not exist
            r["sub_questions"].delete_if { |row_id| !row_ids.include?(row_id) }
          end
          # if all the items for a result is removed, remove this result
          rule["result"].delete_if { |r| r["items"].blank? && r["sub_questions"].blank? }
          # if all the results for a rule is removed, remove this rule
          rules.delete_at(rule_index) if rule["result"].blank?
        elsif [5,6].to_a.include?(rule["rule_type"])
          if rule["result"]["question_id_1"] == question.id
            rule["result"]["items"].delete_if { |i| !item_ids.include?(i[0]) }
          elsif rule["result"]["question_id_2"] == question.id
            rule["result"]["items"].delete_if { |i| !item_ids.include?(i[1]) }
          end
          # if all the results for a rule is removed, remove this rule
          rules.delete_at(rule_index) if rule["result"]["items"].blank?
        end
      when 'question_move'
        question_ids = self.all_questions_id
        if [1,2].to_a.include?(rule["rule_type"])
          # a show/hide questions rule
          conditions_question_ids = rule["conditions"].map { |c| c["question_id"] }
          result_question_ids = rule["result"]
          if conditions_question_ids.include?(question.id.to_s)
            # the conditions include the question to be moved
            result_question_ids.each do |result_question_id|
              if !question_ids.before(question.id, result_question_id)
                rule["conditions"].delete_if { |c| c["question_id"] == question.id.to_s }
              end
            end
          end
          if result_question_ids.include?(question.id.to_s)
            # the results include the question to be moved
            conditions_question_ids.each do |condition_question_id|
              if !question_ids.before(condition_question_id, question.id.to_s)
                rule["result"].delete(question.id.to_s)
              end
            end
          end
          rules.delete_at(rule_index) if rule["conditions"].blank? || rule["result"].blank?
        elsif [3,4].to_a.include?(rule["rule_type"])
          # a show/hide items rule
          conditions_question_ids = rule["conditions"].map { |c| c["question_id"] }
          result_question_ids = rule["result"].map { |r| r["question_id"] }
          if conditions_question_ids.include?(question.id)
            # the conditions include the question to be moved
            result_question_ids.each do |result_question_id|
              if !question_ids.before(question.id, result_question_id)
                rule["conditions"].delete_if { |c| c["question_id"] == question.id }
              end
            end
          end
          if result_question_ids.include?(question.id)
            # the results include the question to be moved
            conditions_question_ids.each do |condition_question_id|
              if !question_ids.before(condition_question_id, question.id)
                rule["result"].delete_if { |r| r["question_id"] == question.id }
              end
            end
          end
          rules.delete_at(rule_index) if rule["conditions"].blank? || rule["result"].blank?
        elsif [5,6].to_a.include?(rule["rule_type"])
          rules.delete_at(rule_index) if question_ids.before(rule["result"]["question_id_1"], rule["result"]["question_id_2"])
        end
      when 'question_delete'
        if ![5,6].include?(rule["rule_type"])
          # not a corresponding items rule
          # adjust the conditions part
          rule["conditions"].delete_if { |c| c["question_id"] == question.id }
          # adjust the result part
          if [1, 2].include?(rule["rule_type"])
            rule["result"].delete(question.id)
          elsif [3, 4].include?(rule["rule_type"])
            rule["result"].delete_if { |r| r["question_id"] == question.id }
          end
          # check whether this logic control rule can be removed
          if rule["conditions"].blank?
            # no conditions, can be removed
            rules.delete_at(rule_index)
          elsif (1..4).to_a.include?(rule["rule_type"]) && rule["result"].blank?
            # no results for the show/hide questions/items, can be removed
            rules.delete_at(rule_index)
          end
        else
          # a corresponding items rule
          if rule["result"]["question_id_1"] == question.id || rule["result"]["question_id_2"] == question.id
            rules.delete_at(rule_index)
          end
        end
      end
    end
    self.save
  end
end