module SurveyComponents::SurveyQuota
  extend ActiveSupport::Concern

  included do
    field :quota, :type => Hash, default: {"rules" => [{"conditions" => [],
                                                        "amount" => 100,
                                                        "finished_count" => 0,
                                                        "submitted_count" => 0}],
                                            "is_exclusive" => true,
                                            "quota_satisfied" => false,
                                            "finished_count" => 0,
                                            "submitted_count" => 0 }
  end

  QUESTION_QUOTA = 1
  REGION_QUOTA = 2
  CHANNEL_QUOTA = 3
  IP_QUOTA = 4
  CONDITION_TYPE = (1..4).to_a

  def show_quota
    return self.quota
  end

  def show_quota_rule(index)
    return ErrorEnum::QUOTA_RULE_NOT_EXIST if @rules.length <= index
    return self.quota["rules"][index]
  end

  def add_quota_rule(rule)
    # check errors
    rule["amount"] = rule["amount"].to_i
    return ErrorEnum::WRONG_QUOTA_RULE_AMOUNT if rule["amount"] <= 0
    rule["finished_count"] = 0
    rule["submitted_count"] = 0
    rule["conditions"] ||= []
    rule["conditions"].each do |condition|
      condition["condition_type"] = condition["condition_type"].to_i
      return ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE if !CONDITION_TYPE.include?(condition["condition_type"])
    end
    self.quota["rules"] << rule
    self.save
    self.refresh_quota_stats
    return self.quota["rules"][-1]
  end

  def update_quota_rule(index, rule)
    # check errors
    rule["amount"] = rule["amount"].to_i
    return ErrorEnum::QUOTA_RULE_NOT_EXIST if self.quota["rules"].length <= index
    return ErrorEnum::WRONG_QUOTA_RULE_AMOUNT if rule["amount"].to_i <= 0
    rule["conditions"] ||= []
    rule["conditions"].each do |condition|
      condition["condition_type"] = condition["condition_type"].to_i
      return ErrorEnum::WRONG_QUOTA_RULE_CONDITION_TYPE if !CONDITION_TYPE.include?(condition["condition_type"].to_i)
    end
    # update the rule
    self.quota["rules"][index] = rule
    self.save
    self.refresh_quota_stats
    return self.quota["rules"][index]
  end

  def delete_quota_rule(index)
    self.quota["rules"].delete_at(index)
    self.save
    self.refresh_quota_stats
  end

  def refresh_quota_stats
    # only make statisics from the answers that are not preview answers
    finished_answers = self.answers.not_preview.finished
    unreviewed_answers = self.answers.not_preview.unreviewed
    # initialze the quota stats
    self.quota["finished_count"] = 0
    self.quota["submitted_count"] = 0
    self.quota["rules"].each do |rule|
      rule["finished_count"] = 0
      rule["submitted_count"] = 0
    end

    # make stats for the finished answers
    finished_answers.each do |answer|
      self.quota["finished_count"] += 1
      self.quota["submitted_count"] += 1
      self.quota["rules"].each do |rule|
        if answer.satisfy_conditions(rule["conditions"])
          rule["finished_count"] += 1
          rule["submitted_count"] += 1
        end
      end
    end

    # make stats for the unreviewed answers
    unreviewed_answers.each do |answer|
      self.quota["submitted_count"] += 1
      self.quota["rules"].each do |rule|
        if answer.satisfy_conditions(rule["conditions"])
          rule["submitted_count"] += 1
        end
      end
    end

    # calculate whether quota is satisfied
    quota["rules"].each do |rule|
      self.quota["quota_satisfied"] &&= rule["finished_count"] >= rule["amount"]
    end
    self.save
    return quota
  end

  def remain_quota_number
    amount = 0
    self.quota["rules"].each do |r|
      amount += r["amount"] - r["finished_count"]
    end
    return amount
  end

  def clone_quota(question_id_mapping)
    self.quota["rules"].each do |quota_rule|
      quota_rule["conditions"].each do |condition|
        if condition["condition_type"] == 1
          condition["name"] = question_id_mapping[condition["name"]]
        end
      end
    end
    self.save
    self.refresh_quota_stats
  end

  def adjust_quota(question, type)
    return if question.question_type == 0
    rules = self.quota["rules"]
    need_refresh_quota = false
    rules.each_with_index do |rule, rule_index|
      next if rule["conditions"].blank?
      case type
      when 'question_update'
        item_ids = question.issue["items"].map { |i| i["id"] }
        item_ids << question.issue["other_item"]["id"] if question.has_other_item
        row_ids = question.issue["items"].map { |i| i["id"] }
        rule["conditions"].each do |c|
          next if c["condition_type"] != 1 || c["name"] != question.id.to_s
          # this condition is about the updated question
          l1 = c["value"].length
          c["value"].delete_if { |item_id| !item_ids.include?(item_id) }
          need_refresh_quota = true if l1 != c["value"].length
        end
        rule["conditions"].delete_if { |c| c["value"].blank? }
        rules.delete_at(rule_index) if rule["conditions"].blank?
      when 'question_delete'
        l1 = rule["conditions"].length
        rule["conditions"].delete_if { |c| c["condition_type"] == 1 && c["name"] == question.id.to_s }
        if l1 != rule["conditions"].length
          rules.delete_at(rule_index) if rule["conditions"].blank?
          need_refresh_quota = true
        end
      end
    end
    self.refresh_quota_stats if need_refresh_quota
    self.save
  end

  def decrease_quota(answer)
    if quota["quota_satisfied"]
      self.refresh_quota_stats
      return
    end
    if answer.is_finish
      quota["finished_count"] = [quota["finished_count"] - 1, 0].max
      quota["submitted_count"] = [quota["submitted_count"] - 1, 0].max
    end
    if answer.is_under_review
      quota["submitted_count"] = [quota["submitted_count"] - 1, 0].max
    end
    quota["rules"].each do |rule|
      next if !answer.satisfy_conditions(rule["conditions"] || [])
      if answer.is_under_review
        # user submits the answer
        rule["submitted_count"] = [rule["submitted_count"] - 1, 0].max
      elsif answer.is_finish
        # user submits the answer, and the answer automatically passes review
        rule["submitted_count"] = [rule["submitted_count"] - 1, 0].max
        rule["finished_count"] = [rule["finished_count"] - 1, 0].max
      end
    end
    save
  end

  def update_quota(answer, old_status)
    if old_status == Answer::EDIT && answer.is_under_review
      # user submits the answer
      quota["submitted_count"] += 1
    elsif old_status == Answer::EDIT && answer.is_finish
      # user submits the answer, and the answer automatically passes review
      quota["submitted_count"] += 1
      quota["finished_count"] += 1
    elsif old_status == Answer::UNDER_REVIEW && answer.is_finish
      # answer passes review
      quota["finished_count"] += 1
    elsif old_status == Answer::UNDER_REVIEW && answer.is_reject
      # answer fails review
      quota["submitted_count"] = [quota["submitted_count"].to_i - 1, 0].max
    end
    quota["rules"].each do |rule|
      next if !answer.satisfy_conditions(rule["conditions"] || [])
      if old_status == Answer::EDIT && answer.is_under_review
        # user submits the answer
        rule["submitted_count"] += 1
      elsif old_status == Answer::EDIT && answer.is_finish
        # user submits the answer, and the answer automatically passes review
        rule["submitted_count"] += 1
        rule["finished_count"] += 1
      elsif old_status == Answer::UNDER_REVIEW && answer.is_finish
        # answer passes review
        rule["finished_count"] += 1
      elsif old_status == Answer::UNDER_REVIEW && answer.is_reject
        # answer fails review
        rule["submitted_count"] = [rule["submitted_count"] - 1, 0].max
      end
    end
    save
  end
end