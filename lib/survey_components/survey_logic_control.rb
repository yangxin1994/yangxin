module SurveyLogicControl
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
    return ErrorEnum::LOGIC_CONTROL_RULE_NOT_EXIST if self.logic_control.length <= index
    return Marshal.load(Marshal.dump(self.logic_control[index]))
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
end