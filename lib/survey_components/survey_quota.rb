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
    (rule["conditions"] || []).each do |condition|
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
        if answer.satisfy_conditions(rule["conditions"], false)
          rule["finished_count"] += 1
          rule["submitted_count"] += 1
        end
      end
    end

    # make stats for the unreviewed answers
    unreviewed_answers.each do |answer|
      self.quota["submitted_count"] += 1
      self.quota["rules"].each do |rule|
        if answer.satisfy_conditions(rule["conditions"], false)
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
end