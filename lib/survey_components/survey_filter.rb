module SurveyComponents::SurveyFilter
  extend ActiveSupport::Concern

  included do
    field :filters, :type => Array, default: []
  end

  QUESTION_QUOTA = 1
  REGION_QUOTA = 2
  CHANNEL_QUOTA = 3
  IP_QUOTA = 4
  CONDITION_TYPE = (0..4).to_a

  def show_filter(index)
    # index = index.to_i
    # return ErrorEnum::FILTER_NOT_EXIST if self.filters[index].nil?
    return self.filters[index.to_i]
  end

  def add_filter(filter)
    filter["conditions"].each do |condition|
      condition["condition_type"] = condition["condition_type"].to_i
      return ErrorEnum::WRONG_FILTER_CONDITION_TYPE if !CONDITION_TYPE.include?(condition["condition_type"])
    end
    self.filters << filter
    self.save
    return self.filters
  end

  def update_filter(index, filter)
    return ErrorEnum::FILTER_NOT_EXIST if self.filters[index].nil?
    filter["conditions"].each do |condition|
      condition["condition_type"] = condition["condition_type"].to_i
      return ErrorEnum::WRONG_FILTER_CONDITION_TYPE if !CONDITION_TYPE.include?(condition["condition_type"].to_i)
    end
    self.filters[index] = filter
    self.save
    return self.filters
  end

  def delete_filter(index)
    self.filters.delete_at(index)
    return self.save
  end

  def clone_filter(question_id_mapping)
    self.filters.each do |filter|
      filter["conditions"].each do |condition|
        if condition["condition_type"] == 1
          condition["name"] = question_id_mapping[condition["name"]]
        end
      end
    end
    self.save
  end

  def adjust_filter(question, type)
    return if question.question_type == 0
    self.filters.each do |rule|
      case type
      when 'question_update'
        item_ids = question.issue["items"].map { |i| i["id"] }
        item_ids << question.issue["other_item"]["id"] if question.has_other_item
        row_ids = question.issue["items"].map { |i| i["id"] }
        rule["conditions"].each do |c|
          next if c["condition_type"] != 1 || c["name"] != question.id
          c["value"].delete_if { |item_id| !item_ids.include?(item_id) }
        end
        rule["conditions"].delete_if { |c| c["value"].blank? }
      when 'question_delete'
        rule["conditions"].delete_if { |c| c["condition_type"] == 1 && c["name"] == question.id }
      end
    end
    self.filters.delete_if { |e| e["conditions"].blank? }
    self.save
  end
end