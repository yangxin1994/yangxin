module SurveysHelper

  def logic_control_tag(question ,logic_controls)
    logic_controls.each do |lc|
      lc["conditions"].each do |condition|
        if condition["question_id"] == question["id"]
          question["is_logic_control"] = true
          question["issue"]["items"].try('each') do |item|
            condition["answer"].include? item["id"]
            item["is_fuzzy"] = condition["fuzzy"]
          end
        end
      end
    end
  end

end