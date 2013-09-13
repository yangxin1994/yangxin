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
    return ErrorEnum::FILTER_NOT_EXIST if self.filters[index].nil?
    return self.filters[index]
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
end